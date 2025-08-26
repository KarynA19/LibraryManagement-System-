-- Enable the event scheduler
SET GLOBAL event_scheduler = ON;
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;

-- Subscriber triggers

-- Drop existing trigger if it exists
DROP EVENT IF EXISTS unfreeze_subscribers;

-- Create the scheduled job to unfreeze subscribers after 30 days
DELIMITER //

CREATE EVENT unfreeze_subscribers
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    -- Update subscribers whose freeze period has ended
    UPDATE subscribers
    SET 
        Status = CASE
            WHEN Expiration >= CURDATE() THEN 'Active'
            ELSE 'In-Active'
        END,
        FreezeUntil = NULL
    WHERE FreezeUntil IS NOT NULL
        AND FreezeUntil <= CURDATE();
END //

DELIMITER ;

-- Daily check for expiration status
DROP EVENT IF EXISTS inactive_subscribers;
DELIMITER //

CREATE EVENT inactive_subscribers
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE subscribers
    SET Status ='In-Active'
    WHERE Expiration < CURDATE();
END //

DELIMITER ;

-- Borrows triggers

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS before_borrow_update;
DROP TRIGGER IF EXISTS after_borrow_update;
DROP PROCEDURE IF EXISTS handle_book_extension;
DROP PROCEDURE IF EXISTS handle_book_declared_lost;
DROP PROCEDURE IF EXISTS handle_lost_book_return;
DROP TRIGGER IF EXISTS update_order_status;
DROP TRIGGER IF EXISTS update_bookcopy_and_borrowed_count;
DROP EVENT IF EXISTS update_overdue_status;
DROP EVENT IF EXISTS apply_penalties;
DROP EVENT IF EXISTS notify_day_before_due_date;

DELIMITER //
-- BEFORE trigger to handle status updates
CREATE TRIGGER before_borrow_update
BEFORE UPDATE ON borrowrecords
FOR EACH ROW
BEGIN
    IF NEW.ActualReturnDate IS NOT NULL 
    AND NEW.Status != 'Lost' 
    AND OLD.Status != 'Lost' THEN
        SET NEW.Status = 
            CASE 
                WHEN DATEDIFF(NEW.ActualReturnDate, NEW.ExpectedReturnDate) <= 0 THEN 'Returned'
                ELSE 'ReturnedLate'
            END;
    END IF;
END //
DELIMITER;

DELIMITER //
-- AFTER trigger to handle related table updates
CREATE TRIGGER after_borrow_update
AFTER UPDATE ON borrowrecords
FOR EACH ROW
BEGIN
    IF NEW.ActualReturnDate IS NOT NULL 
    AND NEW.Status != 'Lost' 
    AND OLD.Status != 'Lost' THEN
        -- Update book copy status
        IF NOT EXISTS (
            SELECT 1 FROM bookcopies
            WHERE CopyID = NEW.CopyID
            AND Status LIKE 'Ordered by%'
        ) THEN
            UPDATE bookcopies
            SET Status = 'Available'
            WHERE CopyID = NEW.CopyID;
        END IF;

        -- Update subscriber's borrowed count
        UPDATE subscribers
        SET CurrentlyBorrowedBooks = CurrentlyBorrowedBooks - 1
        WHERE SubID = NEW.SubID;

        -- Handle late returns and freezing
        IF DATEDIFF(NEW.ActualReturnDate, NEW.ExpectedReturnDate) > 7 THEN
            UPDATE subscribers
            SET FreezeUntil = DATE_ADD(NEW.ActualReturnDate, INTERVAL 30 DAY),
				Status = "Frozen",
                Penalties = Penalties +1
            WHERE SubID = NEW.SubID;
        END IF;
    END IF;
END //
DELIMITER ;


-- Create the procedure to handle lost books
DELIMITER //

CREATE PROCEDURE handle_book_declared_lost(
    IN p_borrow_id INT
)
BEGIN
    DECLARE v_copy_id INT;
    DECLARE v_sub_id INT;
    DECLARE v_book_id INT;
    
    -- Get the copy_id and sub_id from borrow record
    SELECT CopyID, SubID INTO v_copy_id, v_sub_id
    FROM borrowrecords 
    WHERE BorrowID = p_borrow_id;
    
    -- Get book_id from copy
    SELECT BookID INTO v_book_id
    FROM bookcopies
    WHERE CopyID = v_copy_id;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Update borrow record status
    UPDATE borrowrecords 
    SET Status = 'Lost'
    WHERE BorrowID = p_borrow_id;
    
    -- Update book copy status
    UPDATE bookcopies 
    SET Status = 'Lost'
    WHERE CopyID = v_copy_id;
    
    -- Decrement total copies count
    UPDATE books
    SET NumOfCopies = NumOfCopies - 1
    WHERE BookID = v_book_id;
    
    -- Add penalty to subscriber
    UPDATE subscribers
    SET Penalties = Penalties + 1,
        CurrentlyBorrowedBooks = CurrentlyBorrowedBooks - 1,
        Status = 'Frozen',
        FreezeUntil = DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
    WHERE SubID = v_sub_id;
    
    -- Log the action
    INSERT INTO datalogs (SubID, Action, Timestamp)
    VALUES (v_sub_id, CONCAT('Book lost - CopyID: ', v_copy_id), NOW());
    
    COMMIT;
END //

DELIMITER ;

-- Handle lost book returns
DELIMITER //
CREATE PROCEDURE handle_lost_book_return(
    IN p_sub_id INT,
    IN p_copy_id INT,
    IN p_return_date DATE
)
BEGIN
    DECLARE v_book_id INT;
    DECLARE v_expected_return_date DATE;
    DECLARE v_days_late INT;
    DECLARE v_freeze_until DATE;
    DECLARE v_frozen_days INT;
    
    -- Get book_id and expected return date
    SELECT b.BookID, br.ExpectedReturnDate, s.FreezeUntil 
    INTO v_book_id, v_expected_return_date, v_freeze_until
    FROM bookcopies bc
    JOIN books b ON bc.BookID = b.BookID
    JOIN borrowrecords br ON bc.CopyID = br.CopyID
    JOIN subscribers s ON br.SubID = s.SubID
    WHERE bc.CopyID = p_copy_id 
    AND br.SubID = p_sub_id
    AND br.Status = 'Lost';
    
    START TRANSACTION;
    
    -- Calculate days late
    SET v_days_late = DATEDIFF(p_return_date, v_expected_return_date);
    
    -- Update subscriber status based on return timing
    IF v_days_late <= 7 THEN
        -- Early return - lift freeze and reduce penalty
        UPDATE subscribers 
        SET Status = 'Active',
            FreezeUntil = NULL,
            Penalties = GREATEST(0, Penalties - 1)
        WHERE SubID = p_sub_id;
    ELSE
        -- Late return - adjust freeze period if not past 30 days
        SET v_frozen_days = DATEDIFF(v_freeze_until, CURRENT_DATE);
        IF v_frozen_days > 0 THEN
            UPDATE subscribers 
            SET FreezeUntil = DATE_SUB(v_freeze_until, 
                INTERVAL LEAST(v_frozen_days, v_days_late - 7) DAY)
            WHERE SubID = p_sub_id;
        END IF;
    END IF;
    
    -- Update book copy status
    IF NOT EXISTS (
        SELECT 1 FROM bookcopies
        WHERE CopyID = p_copy_id
        AND Status LIKE 'Ordered by%'
    ) THEN
        UPDATE bookcopies
        SET Status = 'Available'
        WHERE CopyID = p_copy_id;
    END IF;
    
    -- Increment copies count
    UPDATE books
    SET NumOfCopies = NumOfCopies + 1
    WHERE BookID = v_book_id;
    
    -- Update borrow record
    UPDATE borrowrecords 
    SET Status = CASE 
            WHEN v_days_late <= 0 THEN 'Returned'
            ELSE 'ReturnedLate'
        END,
        ActualReturnDate = p_return_date
    WHERE CopyID = p_copy_id 
    AND SubID = p_sub_id
    AND Status = 'Lost';
    
    -- Log the action
    -- INSERT INTO datalogs (SubID, Action, Timestamp)
    -- VALUES (p_sub_id, 
    --        CONCAT('Lost book returned - CopyID: ', p_copy_id, 
    --               ' - Days late: ', v_days_late), 
    --        NOW());
    
    COMMIT;
END //

DELIMITER ;

-- Create the procedure to handle book extension
DELIMITER //

CREATE PROCEDURE handle_book_extension(
    IN p_sub_id INT,
    IN p_borrow_id INT,
    IN p_new_return_date DATE
)
BEGIN
    -- Update the borrow status
    UPDATE borrowrecords
    SET Status = 'Borrowed',
        ExpectedReturnDate = p_new_return_date
    WHERE SubID = p_sub_id 
    AND BorrowID = p_borrow_id;

    -- Check for permanent freeze AND late books
    IF (SELECT FreezeUntil 
        FROM subscribers 
        WHERE SubID = p_sub_id) = '2099-12-31'
    AND NOT EXISTS (
        SELECT 1 
        FROM borrowrecords 
        WHERE SubID = p_sub_id
        AND Status = 'Late'
        AND ActualReturnDate IS NULL
        AND DATEDIFF(CURDATE(), ExpectedReturnDate) > 7
    ) THEN
        -- No books over 7 days late, lift freeze
        UPDATE subscribers
        SET FreezeUntil = NULL,
            Status = 'Active'
        WHERE SubID = p_sub_id;
    END IF;
END //

DELIMITER ;

-- Create the trigger to update book copy status and increment borrowed books count
DELIMITER //
CREATE TRIGGER update_bookcopy_and_borrowed_count
AFTER INSERT ON borrowrecords
FOR EACH ROW
BEGIN
    -- Update the status of the book copy to 'Borrowed'
    UPDATE bookcopies
    SET Status = 'Borrowed'
    WHERE CopyID = NEW.CopyID;

    -- Increment the currently borrowed books count for the subscriber
    UPDATE subscribers
    SET CurrentlyBorrowedBooks = CurrentlyBorrowedBooks + 1
    WHERE SubID = NEW.SubID;
END //
DELIMITER ;

DELIMITER //

-- Create the scheduled job to update overdue status
CREATE EVENT update_overdue_status
ON SCHEDULE EVERY 1 DAY
DO
    UPDATE borrowrecords
    SET Status = 'Late'
    WHERE ActualReturnDate IS NULL AND ExpectedReturnDate < CURDATE();
//
DELIMITER ;

-- Create the scheduled job to apply penalties
DELIMITER //

CREATE EVENT apply_penalties
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    -- Apply indefinite freeze for books overdue by more than a week and not yet returned
    UPDATE subscribers s
    JOIN borrowrecords b ON s.SubID = b.SubID
    SET s.Penalties = s.Penalties + 1,
        s.Status = 'Frozen',
        s.FreezeUntil = '2099-12-31'
    WHERE b.Status = 'Late'
      AND b.ActualReturnDate IS NULL
      AND DATEDIFF(CURDATE(), b.ExpectedReturnDate) > 7
      AND s.FreezeUntil IS NULL;
END //

DELIMITER ;

-- Create the scheduled job to notify subscribers a day before due date
DELIMITER //
CREATE EVENT notify_day_before_due_date
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    -- Send notifications to subscribers with books due tomorrow
    INSERT INTO notifications (SubID, Message)
    SELECT 
        b.SubID, 
        CONCAT('Your book "', bk.Title, '" is due tomorrow. Please return it on time.')
    FROM borrowrecords b
    JOIN bookcopies bc ON b.CopyID = bc.CopyID
    JOIN books bk ON bc.BookID = bk.BookID
    WHERE b.ExpectedReturnDate = CURDATE() + INTERVAL 1 DAY
      AND b.ActualReturnDate IS NULL;
END //
DELIMITER ;

-- Orders triggers

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS update_currently_ordered_books;
DROP TRIGGER IF EXISTS add_currently_ordered_books;
DROP TRIGGER IF EXISTS sub_currently_ordered_books;
DROP procedure if exists cancel_overdue_orders_procedure;
DROP procedure if exists send_notification;
DROP EVENT IF EXISTS cancel_overdue_orders;

-- Create the trigger to log new orders and update currently ordered books count
DELIMITER //
CREATE TRIGGER add_currently_ordered_books
AFTER INSERT ON orderrecords
FOR EACH ROW
BEGIN
    -- Update the currently ordered books count
    UPDATE subscribers
    SET CurrentlyOrderedBooks = CurrentlyOrderedBooks + 1
    WHERE SubID = NEW.SubID;
END //
DELIMITER ;

-- Create the trigger to update currently ordered books count
DELIMITER //
CREATE TRIGGER sub_currently_ordered_books
AFTER UPDATE ON orderrecords
FOR EACH ROW
BEGIN
    IF (OLD.Status = 'In-Progress' OR OLD.Status = 'Waiting') AND (NEW.Status = 'Cancelled' OR NEW.Status = 'Completed') THEN
        UPDATE subscribers
        SET CurrentlyOrderedBooks = CurrentlyOrderedBooks - 1
        WHERE SubID = OLD.SubID;
    END IF;
END //
DELIMITER ;

-- Create the trigger to update order status

DELIMITER //
CREATE TRIGGER update_order_status
AFTER INSERT ON borrowrecords
FOR EACH ROW
BEGIN
    DECLARE order_id INT;
    DECLARE book_id INT;

    -- Get the BookID from the bookcopies table
    SELECT BookID INTO book_id
    FROM bookcopies
    WHERE CopyID = NEW.CopyID;

    -- Check if the subscriber has an in-progress order for the borrowed book
    SELECT OrderID INTO order_id
    FROM orderrecords
    WHERE BookID = book_id
      AND SubID = NEW.SubID
      AND Status = 'In-Progress'
    LIMIT 1;

    -- If an in-progress order is found, update its status to completed
    IF order_id IS NOT NULL THEN
        UPDATE orderrecords
        SET Status = 'Completed'
        WHERE OrderID = order_id;
    END IF;
END //

-- Create the scheduled job to cancel overdue orders
DELIMITER //

CREATE PROCEDURE cancel_overdue_orders_procedure()
BEGIN
    DECLARE query_count INT;

    -- Start procedure
    CALL log_debug('Starting procedure');

    -- Check for records
    SELECT COUNT(*) INTO query_count
    FROM orderrecords o
    JOIN books b ON o.BookID = b.BookID
    WHERE o.Status = 'In-Progress'
    AND o.NotificationTimestamp < NOW() - INTERVAL 2 DAY;

    CALL log_debug(CONCAT('Found ', query_count, ' records'));

    -- Cancel overdue orders
    UPDATE orderrecords
    SET Status = 'Cancelled'
    WHERE Status = 'In-Progress'
    AND NotificationTimestamp IS NOT NULL
    AND NotificationTimestamp < NOW() - INTERVAL 2 DAY;

    -- Debug: Log number of cancelled orders
    SET @cancelled_count = ROW_COUNT();
    CALL log_debug(CONCAT('Cancelled ', @cancelled_count, ' overdue orders'));

    -- Find next waiting orders and update them
    UPDATE orderrecords o
    JOIN (
        SELECT o1.OrderID, o1.BookID, o1.SubID, b.Title
        FROM orderrecords o1
        JOIN books b ON o1.BookID = b.BookID
        WHERE o1.Status = 'Waiting'
        AND EXISTS (
            SELECT 1
            FROM orderrecords o2
            WHERE o2.BookID = o1.BookID
            AND o2.Status = 'Cancelled'
            AND o2.NotificationTimestamp < NOW() - INTERVAL 2 DAY
        )
        ORDER BY o1.OrderID ASC
        LIMIT 1
    ) AS next_orders ON o.OrderID = next_orders.OrderID
    SET o.Status = 'In-Progress',
        o.NotificationTimestamp = NOW();

    -- Debug: Log number of updated orders
    SET @updated_count = ROW_COUNT();
    CALL log_debug(CONCAT('Updated ', @updated_count, ' orders to In-Progress'));

    -- Send notifications for updated orders
    INSERT INTO notifications (SubID, Message, Timestamp)
    SELECT next_orders.SubID, 
        CONCAT('Your order for "', next_orders.Title, '" is ready for pick-up. You have 2 days. ', NOW())
    FROM (
        SELECT o1.OrderID, o1.BookID, o1.SubID, b.Title
        FROM orderrecords o1
        JOIN books b ON o1.BookID = b.BookID
        WHERE o1.Status = 'Waiting'
        AND EXISTS (
            SELECT 1
            FROM orderrecords o2
            WHERE o2.BookID = o1.BookID
            AND o2.Status = 'Cancelled'
            AND o2.NotificationTimestamp < NOW() - INTERVAL 2 DAY
        )
        ORDER BY o1.OrderID ASC
        LIMIT 1
    ) AS next_orders;

    CALL log_debug('Notifications sent');

    CALL log_debug('Procedure completed');
END //

DELIMITER ;


DELIMITER //

CREATE EVENT cancel_overdue_orders 
ON SCHEDULE EVERY 1 DAY 
DO 
    CALL cancel_overdue_orders_procedure();
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE send_notification(IN sub_id INT, IN message VARCHAR(255))
BEGIN
    -- Insert the notification into a notifications table
    INSERT INTO notifications (SubID, Message, Timestamp)
    VALUES (sub_id, message, NOW());
END //
DELIMITER ;

-- Logging triggers

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS log_subscriber_creation;
DROP TRIGGER IF EXISTS log_subscriber_deletion;
DROP TRIGGER IF EXISTS log_subscriber_update;
DROP TRIGGER IF EXISTS log_status_change;
DROP TRIGGER IF EXISTS log_penalty_added;
DROP TRIGGER IF EXISTS log_penalties_cleared;
DROP TRIGGER IF EXISTS log_book_borrowed;
DROP TRIGGER IF EXISTS log_book_returned;
DROP TRIGGER IF EXISTS log_book_order;
DROP TRIGGER IF EXISTS log_order_awaiting_pickup;
DROP TRIGGER IF EXISTS log_order_completed;
DROP TRIGGER IF EXISTS log_order_cancelled;


-- Trigger to log subscriber account creation
DELIMITER //
CREATE TRIGGER log_subscriber_creation
AFTER INSERT ON subscribers
FOR EACH ROW
BEGIN
    INSERT INTO datalogs (SubID, Action, Timestamp)
    VALUES (NEW.SubID, 'Account created', NOW());
END //
DELIMITER ;

-- Trigger to log subscriber account deletion
DELIMITER //
CREATE TRIGGER log_subscriber_deletion
BEFORE DELETE ON subscribers
FOR EACH ROW
BEGIN
    INSERT INTO datalogs (SubID, Action, Timestamp)
    VALUES (OLD.SubID, 'Account deleted', NOW());
END //
DELIMITER ;

-- Create triggers to log subscriber actions
DELIMITER //

-- Trigger to log updates to phone number and email
CREATE TRIGGER log_subscriber_update
AFTER UPDATE ON subscribers
FOR EACH ROW
BEGIN
    IF NEW.PhoneNumber <> OLD.PhoneNumber THEN
        INSERT INTO datalogs (SubID, Action, Timestamp)
        VALUES (NEW.SubID, CONCAT('Updated phone number to ', NEW.PhoneNumber), NOW());
    END IF;
    IF NEW.Email <> OLD.Email THEN
        INSERT INTO datalogs (SubID, Action, Timestamp)
        VALUES (NEW.SubID, CONCAT('Updated email to ', NEW.Email), NOW());
    END IF;
END //

DELIMITER ;

-- Trigger to log status changes
DELIMITER //
CREATE TRIGGER log_status_change
AFTER UPDATE ON subscribers
FOR EACH ROW
BEGIN
    IF NEW.Status <> OLD.Status THEN
        INSERT INTO datalogs (SubID, Action, Timestamp)
        VALUES (NEW.SubID, CONCAT('Status changed to ', NEW.Status), NOW());
    END IF;
END //
DELIMITER ;

-- Trigger to log penalties added
DELIMITER //
CREATE TRIGGER log_penalty_added
AFTER UPDATE ON subscribers
FOR EACH ROW
BEGIN
    IF NEW.Penalties > OLD.Penalties THEN
        INSERT INTO datalogs (SubID, Action, Timestamp)
        VALUES (NEW.SubID, CONCAT('Penalty added. Total penalties: ', NEW.Penalties), NOW());
    END IF;
END //

DELIMITER ;

-- Trigger to log penalties cleared
DELIMITER //
CREATE TRIGGER log_penalties_cleared
AFTER UPDATE ON subscribers
FOR EACH ROW
BEGIN
    IF OLD.Penalties > 0 AND NEW.Penalties = 0 THEN
        INSERT INTO datalogs (SubID, Action, Timestamp)
        VALUES (NEW.SubID, 'Penalties cleared', NOW());
    END IF;
END //
DELIMITER ;

-- Trigger to log books borrowed
DELIMITER //

CREATE TRIGGER log_book_borrowed
AFTER INSERT ON borrowrecords
FOR EACH ROW
BEGIN
    DECLARE book_title VARCHAR(255);
    
    -- Retrieve the book title
    SELECT Title INTO book_title
    FROM bookcopies bc
    JOIN books b ON bc.BookID = b.BookID
    WHERE bc.CopyID = NEW.CopyID;
    
    -- Insert the log entry
    INSERT INTO datalogs (SubID, Action, Timestamp)
    VALUES (NEW.SubID, CONCAT('Borrowed ', book_title), NOW());
END //

DELIMITER ;

-- Trigger to log books returned
DELIMITER //

CREATE TRIGGER log_book_returned
AFTER UPDATE ON borrowrecords
FOR EACH ROW
BEGIN
    DECLARE book_title VARCHAR(255);

    IF NEW.ActualReturnDate IS NOT NULL THEN
        -- Retrieve the book title
        SELECT Title INTO book_title
        FROM bookcopies bc
        JOIN books b ON bc.BookID = b.BookID
        WHERE bc.CopyID = NEW.CopyID;
        
        IF (NEW.ActualReturnDate > NEW.ExpectedReturnDate) THEN
            -- Insert the log entry for late return
            INSERT INTO datalogs (SubID, Action, Timestamp)
            VALUES (NEW.SubID, CONCAT('Returned ', book_title, ' (Late)'), NOW());
        ELSE
            -- Insert the log entry for on-time return
            INSERT INTO datalogs (SubID, Action, Timestamp)
            VALUES (NEW.SubID, CONCAT('Returned ', book_title), NOW());
        END IF;
    END IF;
END //

DELIMITER ;

-- Trigger to log book orders
DELIMITER //
CREATE TRIGGER log_book_order
AFTER INSERT ON orderrecords
FOR EACH ROW
BEGIN
    DECLARE book_title VARCHAR(255);
    
    -- Retrieve the book title
    SELECT Title INTO book_title
    FROM books
    WHERE BookID = NEW.BookID;
    
    -- Insert the log entry
    INSERT INTO datalogs (SubID, Action, Timestamp)
    VALUES (NEW.SubID, CONCAT('Ordered ', book_title), NOW());
END //
DELIMITER ;

-- Trigger to log book order awaiting pick-up
DELIMITER //
CREATE TRIGGER log_order_awaiting_pickup
AFTER UPDATE ON orderrecords
FOR EACH ROW
BEGIN
    DECLARE book_title VARCHAR(255);
    IF OLD.Status = 'Waiting' AND NEW.Status = 'In-Progress' THEN
        -- Retrieve the book title
        SELECT Title INTO book_title
        FROM books
        WHERE BookID = OLD.BookID;
        
        -- Insert the log entry
        INSERT INTO datalogs (SubID, Action, Timestamp)
        VALUES (OLD.SubID, CONCAT('Order awaiting pick-up for ', book_title), NOW());
    END IF;
END //

-- Trigger to log book order completion
DELIMITER //
CREATE TRIGGER log_order_completed
AFTER UPDATE ON orderrecords
FOR EACH ROW
BEGIN
    DECLARE book_title VARCHAR(255);
    IF OLD.Status = 'In-Progress' AND NEW.Status = 'Completed' THEN
        -- Retrieve the book title
        SELECT Title INTO book_title
        FROM books
        WHERE BookID = OLD.BookID;
        
        -- Insert the log entry
        INSERT INTO datalogs (SubID, Action, Timestamp)
        VALUES (OLD.SubID, CONCAT('Order completed for ', book_title), NOW());
    END IF;
END //
DELIMITER ;

-- Create the trigger to log cancellations
DELIMITER //
CREATE TRIGGER log_order_cancelled
AFTER UPDATE ON orderrecords
FOR EACH ROW
BEGIN
    DECLARE book_title VARCHAR(255);
	IF OLD.Status IN ('Waiting', 'In-Progress') AND NEW.Status = 'Cancelled' THEN 
        SELECT Title INTO book_title
        FROM books
        WHERE BookID = OLD.BookID;
        
        -- Insert the log entry
        INSERT INTO datalogs (SubID, Action, Timestamp)
        VALUES (OLD.SubID, CONCAT('Order cancelled for ', book_title), NOW());
    END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS log_debug;

DELIMITER //

CREATE PROCEDURE log_debug(IN debug_message VARCHAR(500))
BEGIN
    INSERT INTO debug_log (message) VALUES (debug_message);
END //

DELIMITER ;


-- Monthly reports --
-- First drop all procedures
DROP PROCEDURE IF EXISTS GenerateMonthlyReports;
DROP PROCEDURE IF EXISTS GenerateBorrowReport;
DROP PROCEDURE IF EXISTS GenerateSubscriberReport;

-- Drop and recreate temp tables
DROP TABLE IF EXISTS temp_borrow_report;
DROP TABLE IF EXISTS temp_subscriber_report;

-- Create temp tables to store reports
CREATE TABLE temp_borrow_report (
    Genre VARCHAR(50),
    TotalBorrows INT,
    AvgBorrowDays DECIMAL(10,2),
    OnTimeReturns INT,
    LateNoPenalty INT,
    LateWithPenaltyOrLost INT,
    ReportMonth INT,
    ReportYear INT
);

CREATE TABLE temp_subscriber_report (
    SubStatus VARCHAR(20),
    StatusCount INT,
    WithPenalties INT,
    AvgPenalties DECIMAL(10,2),
    ReportMonth INT,
    ReportYear INT
);

DELIMITER //
-- Procedure for borrow statistics
CREATE PROCEDURE GenerateBorrowReport(IN report_date DATE)
BEGIN
    DELETE FROM temp_borrow_report;
    INSERT INTO temp_borrow_report
    SELECT 
        b.Genre,
        COUNT(*) as TotalBorrows,
        AVG(DATEDIFF(COALESCE(br.ActualReturnDate, report_date), br.BorrowDate)) as AvgBorrowDays,
        SUM(CASE WHEN br.ActualReturnDate <= br.ExpectedReturnDate THEN 1 ELSE 0 END) as OnTimeReturns,
        SUM(CASE WHEN br.ActualReturnDate > br.ExpectedReturnDate 
            AND DATEDIFF(br.ActualReturnDate, br.ExpectedReturnDate) <= 7 THEN 1 ELSE 0 END) as LateNoPenalty,
        SUM(CASE WHEN (br.ActualReturnDate > br.ExpectedReturnDate 
            AND DATEDIFF(br.ActualReturnDate, br.ExpectedReturnDate) > 7)
            OR br.Status = 'Lost' THEN 1 ELSE 0 END) as LateWithPenaltyOrLost,
        MONTH(report_date) as ReportMonth,
        YEAR(report_date) as ReportYear
    FROM borrowrecords br
    JOIN bookcopies bc ON br.CopyID = bc.CopyID
    JOIN books b ON bc.BookID = b.BookID
    WHERE MONTH(br.BorrowDate) = MONTH(report_date)
    AND YEAR(br.BorrowDate) = YEAR(report_date)
    GROUP BY b.Genre;
END //

DELIMITER ;

DELIMITER //
CREATE PROCEDURE GenerateSubscriberReport(IN report_date DATE)
BEGIN
    DELETE FROM temp_subscriber_report;

    INSERT INTO temp_subscriber_report
    SELECT 
        effective_status as SubStatus,
        COUNT(*) as StatusCount,
        SUM(CASE 
            WHEN EXISTS (
                SELECT 1 FROM borrowrecords br 
                WHERE br.SubID = s.SubID
                AND br.Status = 'ReturnedLate'
                AND br.ActualReturnDate > DATE_ADD(br.ExpectedReturnDate, INTERVAL 7 DAY)
                AND MONTH(br.ActualReturnDate) = MONTH(report_date)
                AND YEAR(br.ActualReturnDate) = YEAR(report_date)
            ) THEN 1 ELSE 0 END) as WithPenalties,
        ROUND(AVG(
            IFNULL((
                SELECT COUNT(*)
                FROM borrowrecords br
                WHERE br.SubID = s.SubID
                AND br.Status = 'ReturnedLate'
                AND br.ActualReturnDate > DATE_ADD(br.ExpectedReturnDate, INTERVAL 7 DAY)
                AND MONTH(br.ActualReturnDate) = MONTH(report_date)
                AND YEAR(br.ActualReturnDate) = YEAR(report_date)
            ), 0)
        ), 2) as AvgPenalties,
        MONTH(report_date) as ReportMonth,
        YEAR(report_date) as ReportYear
    FROM (
        SELECT 
            SubID,
            CASE 
                WHEN Expiration < report_date THEN 'In-Active'
                ELSE Status 
            END as effective_status
        FROM subscribers 
        WHERE Joined <= report_date
    ) s
    GROUP BY effective_status;
END //
DELIMITER ;


DELIMITER //
-- Procedure to generate both reports
CREATE PROCEDURE GenerateMonthlyReports(IN report_date DATE)
BEGIN
    CALL GenerateBorrowReport(report_date);
    CALL GenerateSubscriberReport(report_date);
END //

DELIMITER ;