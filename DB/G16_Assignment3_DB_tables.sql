-- Drop the schema if it already exists
DROP SCHEMA IF EXISTS `blib`;

-- Create the schema
CREATE SCHEMA `blib` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- Set the schema as the default
USE `blib`;

-- Create the tables
CREATE TABLE IF NOT EXISTS `books` (
  `BookID` int NOT NULL COMMENT 'Book ID',
  `Title` varchar(255) NOT NULL COMMENT 'Book Title',
  `Author` varchar(255) NOT NULL COMMENT 'Book Author',
  `Genre` varchar(50) NOT NULL COMMENT 'Book Genre',
  `Description` varchar(1000) DEFAULT NULL COMMENT 'Book Description',
  `NumOfCopies` int NOT NULL COMMENT 'Number of copies available',
  PRIMARY KEY (`BookID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `bookcopies` (
  `CopyID` int NOT NULL COMMENT 'Book copy ID',
  `BookID` int NOT NULL COMMENT 'Book ID (foreign)',
  `Location` varchar(100) NOT NULL COMMENT 'Location in library shelf',
  `Status` varchar(50) NOT NULL COMMENT 'Status: \\nAvailable\\nBorrowed\\nOrdered',
  PRIMARY KEY (`CopyID`),
  KEY `BookID_idx` (`BookID`),
  CONSTRAINT `BookID` FOREIGN KEY (`BookID`) REFERENCES `books` (`BookID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `librarians` (
  `LibID` int NOT NULL COMMENT 'Unique ID for each librarian',
  `Name` varchar(255) NOT NULL COMMENT 'Librarian Name',
  `LastFetched` timestamp DEFAULT CURRENT_TIMESTAMP COMMENT 'Last fetched notification',
  PRIMARY KEY (`LibID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `subscribers` (
  `SubID` int NOT NULL AUTO_INCREMENT COMMENT 'Subscriber ID',
  `Name` varchar(255) NOT NULL COMMENT 'Subscriber name',
  `Status` varchar(50) NOT NULL COMMENT 'Status (Active, In-Active, Frozen)',
  `PhoneNumber` varchar(15) NOT NULL UNIQUE COMMENT '05x-xxxxxx',
  `Email` varchar(255) NOT NULL UNIQUE COMMENT 'valid@url.ending',
  `Penalties` int DEFAULT 0 COMMENT 'Number of penalties accumilated',
  `FreezeUntil` date DEFAULT NULL COMMENT 'Date until the subscriber is frozen',
  `Joined` date NOT NULL COMMENT 'Date joined (YYYY-MM-DD)',
  `Expiration` date NOT NULL COMMENT 'Expiration date (YYYY-MM-DD)',
  `CurrentlyBorrowedBooks` int DEFAULT 0 COMMENT 'Number of currently borrowed books',
  `CurrentlyOrderedBooks` int DEFAULT 0 COMMENT 'Number of currently ordered books',
  `LastFetched` timestamp DEFAULT CURRENT_TIMESTAMP COMMENT 'Last fetched notification',
  PRIMARY KEY (`SubID`)
) ENGINE=InnoDB AUTO_INCREMENT=100001 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `borrowrecords` (
  `BorrowID` int AUTO_INCREMENT COMMENT 'Borrow ID',
  `CopyID` int NOT NULL COMMENT 'Copy ID - Foreign key referencing bookcopies',
  `SubID` int NOT NULL COMMENT 'Subscriber ID - Foreign key referencing subscribers',
  `BorrowDate` date NOT NULL COMMENT 'Borrowing date',
  `ExpectedReturnDate` date NOT NULL COMMENT 'Expected returning date',
  `ActualReturnDate` date DEFAULT NULL COMMENT 'Actual returning date',
  `Status` varchar(50) NOT NULL COMMENT 'Status:\nBorrowed\nReturned\nReturnedLate\nLate\nLost',
  PRIMARY KEY (`BorrowID`),
  KEY `CopyID_idx` (`CopyID`),
  KEY `SubID_idx` (`SubID`),
  CONSTRAINT `BorrowCopyID` FOREIGN KEY (`CopyID`) REFERENCES `bookcopies` (`CopyID`),
  CONSTRAINT `BorrowSubID` FOREIGN KEY (`SubID`) REFERENCES `subscribers` (`SubID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `orderrecords` (
  `OrderID` int NOT NULL AUTO_INCREMENT COMMENT 'Order ID',
  `BookID` int NOT NULL COMMENT 'Book ID - Foreign key referencing books',
  `SubID` int NOT NULL COMMENT 'Subscriber ID - Foreign key referencing subscribers',
  `OrderDate` date NOT NULL COMMENT 'Ordered date',
  `Status` varchar(50) NOT NULL COMMENT 'Status:\\nWaiting\\nIn-Progress\\nCancelled (2 days wait or cancel button)\\nCompleted',
  `NotificationTimestamp` TIMESTAMP DEFAULT NULL COMMENT 'Timestamp when the subscriber was notified',
  PRIMARY KEY (`OrderID`),
  KEY `BookID_idx` (`BookID`),
  KEY `SubID_idx` (`SubID`),
  CONSTRAINT `RecordsBookID` FOREIGN KEY (`BookID`) REFERENCES `books` (`BookID`),
  CONSTRAINT `RecordsSubID` FOREIGN KEY (`SubID`) REFERENCES `subscribers` (`SubID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `datalogs` (
  `LogID` int NOT NULL AUTO_INCREMENT COMMENT 'Unique log identifier',
  `SubID` int NOT NULL COMMENT 'Subscriber ID',
  `Action` varchar(255) COMMENT 'Description of the action',
  `Timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date and time of the action',
  PRIMARY KEY (`LogID`),
  UNIQUE KEY `LogID_UNIQUE` (`LogID`),
  KEY `LogsSubID_idx` (`SubID`),
  CONSTRAINT `LogsSubID` FOREIGN KEY (`SubID`) REFERENCES `subscribers` (`SubID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `notifications` (
    NotificationID INT AUTO_INCREMENT PRIMARY KEY,
    SubID INT NULL,
    LibID INT NULL,
    Message VARCHAR(255),
    Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (SubID) REFERENCES subscribers(SubID),
    FOREIGN KEY (LibID) REFERENCES librarians(LibID),
    CONSTRAINT chk_only_one_id CHECK (
        (SubID IS NULL AND LibID IS NOT NULL) OR
        (SubID IS NOT NULL AND LibID IS NULL)
    )
);

CREATE TABLE IF NOT EXISTS `debug_log` (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(500),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);