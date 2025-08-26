SET SQL_SAFE_UPDATES = 0;

DROP PROCEDURE IF EXISTS GenerateSubscribers;
DELIMITER //

CREATE PROCEDURE GenerateSubscribers()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE subID INT DEFAULT 10000;
    DECLARE randomPhone VARCHAR(15);
    DECLARE randomPrefix VARCHAR(3);
    DECLARE randomEmail VARCHAR(255);
    DECLARE randomStatus VARCHAR(50);
    DECLARE randomJoined DATE;
    DECLARE randomExpiration DATE;
    DECLARE startDate DATE DEFAULT '2024-01-01';
    DECLARE lastDate DATE DEFAULT '2024-01-01';
    DECLARE attempts INT;
    DECLARE phoneExists INT;

    WHILE i <= 500 DO
        SET attempts = 0;
        phone_generation: LOOP
            SET randomPrefix = ELT(FLOOR(RAND() * 4) + 1, '050', '052', '053', '054');
            SET randomPhone = CONCAT(randomPrefix, '-', FLOOR(RAND() * 9000000) + 1000000);
            
            -- Check if phone exists
            SELECT COUNT(*) INTO phoneExists 
            FROM subscribers 
            WHERE PhoneNumber = randomPhone;
            
            IF phoneExists = 0 OR attempts >= 10 THEN
                LEAVE phone_generation;
            END IF;
            
            SET attempts = attempts + 1;
        END LOOP;

        IF phoneExists = 0 THEN
            SET randomJoined = DATE_ADD(lastDate, INTERVAL FLOOR(RAND() * 2.3) DAY);
            SET lastDate = randomJoined;
            
            SET randomEmail = CONCAT('subscriber', i, '@example.com');
            SET randomExpiration = DATE_ADD(randomJoined, INTERVAL 1 YEAR);

            IF CURDATE() > randomExpiration THEN
                SET randomStatus = 'In-Active';
            ELSE
                SET randomStatus = 'Active';
            END IF;

            INSERT INTO subscribers (Name, Status, PhoneNumber, Email, Joined, Expiration)
            VALUES (
                CONCAT('Subscriber_', i),
                randomStatus,
                randomPhone,
                randomEmail,
                randomJoined,
                randomExpiration
            );

            SET i = i + 1;
        END IF;
    END WHILE;
END //

DELIMITER ;

CALL GenerateSubscribers();

-- יצירת librarians
INSERT INTO librarians (LibID, Name) VALUES
(1, 'Emma Watson'),
(2, 'Daniel Radcliffe'),
(3, 'Rupert Grint'),
(4, 'Tom Felton'),
(5, 'Bonnie Wright');

INSERT INTO books (BookID, Title, Author, Genre, Description, NumOfCopies) VALUES
(100, 'The Lost Treasure', 'John Smith', 'Adventure', 'An epic journey to find a lost treasure hidden in a mysterious island.', 5),
(200, 'Dark Secrets', 'Sarah Jones', 'Thriller', 'A detective uncovers dangerous secrets in a small town, risking her life to expose the truth.', 7),
(300, 'Mysteries of the Deep', 'Michael White', 'Science Fiction', 'Exploring the unknown depths of space, where humanity faces its biggest challenge yet.', 3),
(400, 'Whispers in the Shadows', 'Emily Brown', 'Horror', 'A chilling tale of a haunted house with a dark history that keeps haunting the living.', 4),
(500, 'The Silent Melody', 'David Lee', 'Romance', 'A heartwarming love story between two souls torn apart by fate, but destined to be together.', 2),
(600, 'Through the Storm', 'Linda Davis', 'Drama', 'A family battles through hard times, learning the value of love, resilience, and hope.', 6),
(700, 'Echoes of the Past', 'Chris Miller', 'Historical Fiction', 'A gripping story set in ancient times, where historical figures struggle for power and survival.', 3),
(800, 'Chasing the Horizon', 'Patricia Clark', 'Fantasy', 'A young hero embarks on an adventure to save their kingdom from an impending doom.', 8),
(900, 'The Codebreaker', 'James Taylor', 'Mystery', 'A brilliant codebreaker must decipher an ancient message that holds the key to a hidden treasure.', 5),
(1000, 'New Horizons', 'Nancy Wilson', 'Science Fiction', 'A crew aboard a spaceship explores new galaxies, only to find a world full of unimaginable danger.', 10),
(1100, 'The Last Voyage', 'Andrew Harris', 'Adventure', 'A group of explorers set sail to discover a lost continent filled with untold mysteries.', 4),
(1200, 'Dark Tide', 'Rachel Young', 'Thriller', 'A deep-sea explorer uncovers a conspiracy that could change the world forever.', 7),
(1300, 'The Rebel King', 'Brian Scott', 'Fantasy', 'A young prince fights for his kingdom in an epic battle against an evil sorcerer.', 6),
(1400, 'Shadows of the Mind', 'Olivia Martin', 'Psychological Thriller', 'A psychiatrist must solve the mystery of her patient’s nightmares that are haunting her own life.', 5),
(1500, 'Silent Warriors', 'Jonathan King', 'War', 'The story of an elite group of soldiers who must complete a dangerous mission behind enemy lines.', 2),
(1600, 'The Hidden Kingdom', 'Jessica Moore', 'Fantasy', 'A mythical kingdom is hidden in plain sight, and only a chosen few can unlock its secrets.', 8),
(1700, 'Beneath the Surface', 'Mark Robinson', 'Horror', 'An underwater research team encounters horrifying creatures lurking beneath the ocean.', 3),
(1800, 'The Ancient Spell', 'Laura Garcia', 'Fantasy', 'A lost spell is discovered, and with it, the power to change the fate of the world is unleashed.', 9),
(1900, 'Into the Fire', 'Michael Harris', 'Adventure', 'A thrilling tale of survival in the wilderness, where a group of strangers must work together to survive.', 4),
(2000, 'Echoes of Tomorrow', 'Samuel Brown', 'Science Fiction', 'A scientist must face the consequences of time travel when he inadvertently alters history.', 5),
(2100, 'Blood Moon', 'Isabel King', 'Horror', 'A terrifying story of an ancient curse that is awakened during a rare celestial event.', 2),
(2200, 'The Mountain Path', 'Charles Miller', 'Adventure', 'A mountain climber embarks on an impossible journey to reach the top of the world’s most dangerous peak.', 6),
(2300, 'The Red Phoenix', 'Samantha Lee', 'Historical Fiction', 'A tale of love and war set against the backdrop of the ancient Chinese dynasties.', 7),
(2400, 'Into the Abyss', 'David Walker', 'Mystery', 'A team of investigators uncover secrets buried deep beneath the surface of an abandoned city.', 5),
(2500, 'The Timekeeper', 'Elizabeth Taylor', 'Fantasy', 'A young woman finds a timepiece that holds the power to travel between different worlds and timelines.', 9),
(2600, 'The Silent Forest', 'Henry Evans', 'Horror', 'A group of friends visit a remote forest, unaware that an ancient evil awaits them.', 4),
(2700, 'Rise of the Titans', 'Sophia Clark', 'Fantasy', 'Titans return to the earth to reclaim their place as rulers of the world, causing chaos and destruction.', 10),
(2800, 'The Seeker', 'John Carter', 'Adventure', 'A lone adventurer searches for a mythical artifact said to grant unimaginable power.', 3),
(2900, 'The Last Chance', 'Rachel Moore', 'Romance', 'Two people on the brink of separation find their way back to each other after a life-changing event.', 6),
(3000, 'Beyond the Stars', 'Daniel Scott', 'Science Fiction', 'A journey through the cosmos reveals the existence of life forms far beyond human understanding.', 7),
(3100, 'The Protector', 'Charlotte Evans', 'Action', 'A former soldier must protect a high-profile target from an assassin sent by an unknown force.', 10),
(3200, 'The Lost Heir', 'Tom Harris', 'Historical Fiction', 'A young orphan discovers they are the heir to a forgotten empire and must fight to claim the throne.', 10),
(3300, 'Silent Fury', 'Olivia Brown', 'Action', 'A vigilante fights against the corrupt elite to bring justice to the oppressed.', 10),
(3400, 'Frozen Memories', 'David Young', 'Romance', 'A woman with amnesia falls in love with the person who claims to be her past, but she doesn’t remember him.', 10),
(3500, 'The Phantom Knight', 'James Smith', 'Fantasy', 'A legendary knight returns from the dead to fight against an army of dark sorcerers threatening the kingdom.', 10),
(3600, 'The Unseen Enemy', 'Mary Wilson', 'Mystery', 'A series of crimes are committed by an invisible enemy, and only a detective with special skills can solve the case.', 10),
(3700, 'The Golden City', 'Michael Clark', 'Adventure', 'An expedition into the heart of an ancient jungle uncovers a lost city full of treasure and peril.', 10),
(3800, 'The Black Veil', 'Anna Miller', 'Horror', 'A young woman inherits an old mansion where a deadly secret waits to be uncovered.', 10),
(3900, 'The Secret Path', 'Joseph Robinson', 'Thriller', 'A detective follows a mysterious trail of clues leading to a powerful criminal organization.', 10),
(4000, 'The Silent War', 'Henry Green', 'War', 'A brutal conflict between two empires threatens the fate of the world, and only a few can prevent the inevitable destruction.', 8);

INSERT INTO bookcopies (CopyID, BookID, Location, Status) VALUES
(101, 100, 'Shelf A1', 'Available'),
(102, 100, 'Shelf A1', 'Available'),
(103, 100, 'Shelf A2', 'Available'),
(104, 100, 'Shelf A2', 'Available'),
(105, 100, 'Shelf A2', 'Available'),
(201, 200, 'Shelf B1', 'Available'),
(202, 200, 'Shelf B1', 'Available'),
(203, 200, 'Shelf B2', 'Available'),
(204, 200, 'Shelf B2', 'Available'),
(205, 200, 'Shelf B2', 'Available'),
(206, 200, 'Shelf B3', 'Available'),
(207, 200, 'Shelf B3', 'Available'),
(301, 300, 'Shelf C1', 'Available'),
(302, 300, 'Shelf C1', 'Available'),
(303, 300, 'Shelf C2', 'Available'),
(401, 400, 'Shelf D1', 'Available'),
(402, 400, 'Shelf D1', 'Available'),
(403, 400, 'Shelf D2', 'Available'),
(404, 400, 'Shelf D2', 'Available'),
(501, 500, 'Shelf E1', 'Available'),
(502, 500, 'Shelf E1', 'Available'),
(601, 600, 'Shelf F1', 'Available'),
(602, 600, 'Shelf F1', 'Available'),
(603, 600, 'Shelf F2', 'Available'),
(604, 600, 'Shelf F2', 'Available'),
(605, 600, 'Shelf F3', 'Available'),
(606, 600, 'Shelf F3', 'Available'),
(701, 700, 'Shelf G1', 'Available'),
(702, 700, 'Shelf G1', 'Available'),
(703, 700, 'Shelf G2', 'Available'),
(801, 800, 'Shelf H1', 'Available'),
(802, 800, 'Shelf H1', 'Available'),
(803, 800, 'Shelf H2', 'Available'),
(804, 800, 'Shelf H2', 'Available'),
(805, 800, 'Shelf H3', 'Available'),
(806, 800, 'Shelf H3', 'Available'),
(807, 800, 'Shelf H4', 'Available'),
(808, 800, 'Shelf H4', 'Available'),
(901, 900, 'Shelf I1', 'Available'),
(902, 900, 'Shelf I1', 'Available'),
(903, 900, 'Shelf I2', 'Available'),
(904, 900, 'Shelf I2', 'Available'),
(905, 900, 'Shelf I3', 'Available'),
(1001, 1000, 'Shelf J1', 'Available'),
(1002, 1000, 'Shelf J1', 'Available'),
(1003, 1000, 'Shelf J2', 'Available'),
(1004, 1000, 'Shelf J2', 'Available'),
(1005, 1000, 'Shelf J3', 'Available'),
(1006, 1000, 'Shelf J3', 'Available'),
(1007, 1000, 'Shelf J4', 'Available'),
(1008, 1000, 'Shelf J4', 'Available'),
(1009, 1000, 'Shelf J5', 'Available'),
(1010, 1000, 'Shelf J5', 'Available'),
(1101, 1100, 'Shelf K1', 'Available'),
(1102, 1100, 'Shelf K1', 'Available'),
(1103, 1100, 'Shelf K2', 'Available'),
(1104, 1100, 'Shelf K2', 'Available'),
(1201, 1200, 'Shelf L1', 'Available'),
(1202, 1200, 'Shelf L1', 'Available'),
(1203, 1200, 'Shelf L2', 'Available'),
(1204, 1200, 'Shelf L2', 'Available'),
(1205, 1200, 'Shelf L3', 'Available'),
(1206, 1200, 'Shelf L3', 'Available'),
(1207, 1200, 'Shelf L4', 'Available'),
(1301, 1300, 'Shelf M1', 'Available'),
(1302, 1300, 'Shelf M1', 'Available'),
(1303, 1300, 'Shelf M2', 'Available'),
(1304, 1300, 'Shelf M2', 'Available'),
(1305, 1300, 'Shelf M3', 'Available'),
(1306, 1300, 'Shelf M3', 'Available'),
(1401, 1400, 'Shelf N1', 'Available'),
(1402, 1400, 'Shelf N1', 'Available'),
(1403, 1400, 'Shelf N2', 'Available'),
(1404, 1400, 'Shelf N2', 'Available'),
(1405, 1400, 'Shelf N3', 'Available'),
(1501, 1500, 'Shelf O1', 'Available'),
(1502, 1500, 'Shelf O1', 'Available'),
(1601, 1600, 'Shelf P1', 'Available'),
(1602, 1600, 'Shelf P1', 'Available'),
(1603, 1600, 'Shelf P2', 'Available'),
(1604, 1600, 'Shelf P2', 'Available'),
(1605, 1600, 'Shelf P3', 'Available'),
(1606, 1600, 'Shelf P3', 'Available'),
(1607, 1600, 'Shelf P4', 'Available'),
(1608, 1600, 'Shelf P4', 'Available'),
(1701, 1700, 'Shelf Q1', 'Available'),
(1702, 1700, 'Shelf Q1', 'Available'),
(1703, 1700, 'Shelf Q2', 'Available'),
(1801, 1800, 'Shelf R1', 'Available'),
(1802, 1800, 'Shelf R1', 'Available'),
(1803, 1800, 'Shelf R2', 'Available'),
(1804, 1800, 'Shelf R2', 'Available'),
(1805, 1800, 'Shelf R3', 'Available'),
(1806, 1800, 'Shelf R3', 'Available'),
(1807, 1800, 'Shelf R4', 'Available'),
(1808, 1800, 'Shelf R4', 'Available'),
(1809, 1800, 'Shelf R5', 'Available'),
(1901, 1900, 'Shelf S1', 'Available'),
(1902, 1900, 'Shelf S1', 'Available'),
(1903, 1900, 'Shelf S2', 'Available'),
(1904, 1900, 'Shelf S2', 'Available'),
(2001, 2000, 'Shelf T1', 'Available'),
(2002, 2000, 'Shelf T1', 'Available'),
(2003, 2000, 'Shelf T2', 'Available'),
(2004, 2000, 'Shelf T2', 'Available'),
(2005, 2000, 'Shelf T3', 'Available'),
(2101, 2100, 'Shelf U1', 'Available'),
(2102, 2100, 'Shelf U1', 'Available'),
(2201, 2200, 'Shelf V1', 'Available'),
(2202, 2200, 'Shelf V1', 'Available'),
(2203, 2200, 'Shelf V2', 'Available'),
(2204, 2200, 'Shelf V2', 'Available'),
(2205, 2200, 'Shelf V3', 'Available'),
(2206, 2200, 'Shelf V3', 'Available'),
(2301, 2300, 'Shelf W1', 'Available'),
(2302, 2300, 'Shelf W1', 'Available'),
(2303, 2300, 'Shelf W2', 'Available'),
(2304, 2300, 'Shelf W2', 'Available'),
(2305, 2300, 'Shelf W3', 'Available'),
(2306, 2300, 'Shelf W3', 'Available'),
(2307, 2300, 'Shelf W4', 'Available'),
(2401, 2400, 'Shelf X1', 'Available'),
(2402, 2400, 'Shelf X1', 'Available'),
(2403, 2400, 'Shelf X2', 'Available'),
(2404, 2400, 'Shelf X2', 'Available'),
(2405, 2400, 'Shelf X3', 'Available'),
(2501, 2500, 'Shelf Y1', 'Available'),
(2502, 2500, 'Shelf Y1', 'Available'),
(2503, 2500, 'Shelf Y2', 'Available'),
(2504, 2500, 'Shelf Y2', 'Available'),
(2505, 2500, 'Shelf Y3', 'Available'),
(2506, 2500, 'Shelf Y3', 'Available'),
(2507, 2500, 'Shelf Y4', 'Available'),
(2508, 2500, 'Shelf Y4', 'Available'),
(2509, 2500, 'Shelf Y5', 'Available'),
(2601, 2600, 'Shelf Z1', 'Available'),
(2602, 2600, 'Shelf Z1', 'Available'),
(2603, 2600, 'Shelf Z2', 'Available'),
(2604, 2600, 'Shelf Z2', 'Available'),
(2701, 2700, 'Shelf AA1', 'Available'),
(2702, 2700, 'Shelf AA1', 'Available'),
(2703, 2700, 'Shelf AA2', 'Available'),
(2704, 2700, 'Shelf AA2', 'Available'),
(2705, 2700, 'Shelf AA3', 'Available'),
(2706, 2700, 'Shelf AA3', 'Available'),
(2707, 2700, 'Shelf AA4', 'Available'),
(2708, 2700, 'Shelf AA4', 'Available'),
(2709, 2700, 'Shelf AA5', 'Available'),
(2710, 2700, 'Shelf AA5', 'Available'),
(2801, 2800, 'Shelf AB1', 'Available'),
(2802, 2800, 'Shelf AB1', 'Available'),
(2803, 2800, 'Shelf AB2', 'Available'),
(2901, 2900, 'Shelf AC1', 'Available'),
(2902, 2900, 'Shelf AC1', 'Available'),
(2903, 2900, 'Shelf AC2', 'Available'),
(2904, 2900, 'Shelf AC2', 'Available'),
(2905, 2900, 'Shelf AC3', 'Available'),
(2906, 2900, 'Shelf AC3', 'Available'),
(3001, 3000, 'Shelf AD1', 'Available'),
(3002, 3000, 'Shelf AD1', 'Available'),
(3003, 3000, 'Shelf AD2', 'Available'),
(3004, 3000, 'Shelf AD2', 'Available'),
(3005, 3000, 'Shelf AD3', 'Available'),
(3006, 3000, 'Shelf AD3', 'Available'),
(3007, 3000, 'Shelf AD4', 'Available'),
(3101, 3100, 'Shelf AE1', 'Available'),
(3102, 3100, 'Shelf AE1', 'Available'),
(3103, 3100, 'Shelf AE2', 'Available'),
(3104, 3100, 'Shelf AE2', 'Available'),
(3105, 3100, 'Shelf AE3', 'Available'),
(3106, 3100, 'Shelf AE3', 'Available'),
(3107, 3100, 'Shelf AE4', 'Available'),
(3108, 3100, 'Shelf AE4', 'Available'),
(3109, 3100, 'Shelf AE5', 'Available'),
(3110, 3100, 'Shelf AE5', 'Available'),
(3201, 3200, 'Shelf AF1', 'Available'),
(3202, 3200, 'Shelf AF1', 'Available'),
(3203, 3200, 'Shelf AF2', 'Available'),
(3204, 3200, 'Shelf AF2', 'Available'),
(3205, 3200, 'Shelf AF3', 'Available'),
(3206, 3200, 'Shelf AF3', 'Available'),
(3207, 3200, 'Shelf AF4', 'Available'),
(3208, 3200, 'Shelf AF4', 'Available'),
(3209, 3200, 'Shelf AF5', 'Available'),
(3210, 3200, 'Shelf AF5', 'Available'),
(3301, 3300, 'Shelf AG1', 'Available'),
(3302, 3300, 'Shelf AG1', 'Available'),
(3303, 3300, 'Shelf AG2', 'Available'),
(3304, 3300, 'Shelf AG2', 'Available'),
(3305, 3300, 'Shelf AG3', 'Available'),
(3306, 3300, 'Shelf AG3', 'Available'),
(3307, 3300, 'Shelf AG4', 'Available'),
(3308, 3300, 'Shelf AG4', 'Available'),
(3309, 3300, 'Shelf AG5', 'Available'),
(3310, 3300, 'Shelf AG5', 'Available'),
(3401, 3400, 'Shelf AH1', 'Available'),
(3402, 3400, 'Shelf AH1', 'Available'),
(3403, 3400, 'Shelf AH2', 'Available'),
(3404, 3400, 'Shelf AH2', 'Available'),
(3405, 3400, 'Shelf AH3', 'Available'),
(3406, 3400, 'Shelf AH3', 'Available'),
(3407, 3400, 'Shelf AH4', 'Available'),
(3408, 3400, 'Shelf AH4', 'Available'),
(3409, 3400, 'Shelf AH5', 'Available'),
(3410, 3400, 'Shelf AH5', 'Available'),
(3501, 3500, 'Shelf AI1', 'Available'),
(3502, 3500, 'Shelf AI1', 'Available'),
(3503, 3500, 'Shelf AI2', 'Available'),
(3504, 3500, 'Shelf AI2', 'Available'),
(3505, 3500, 'Shelf AI3', 'Available'),
(3506, 3500, 'Shelf AI3', 'Available'),
(3507, 3500, 'Shelf AI4', 'Available'),
(3508, 3500, 'Shelf AI4', 'Available'),
(3509, 3500, 'Shelf AI5', 'Available'),
(3510, 3500, 'Shelf AI5', 'Available'),
(3601, 3600, 'Shelf AJ1', 'Available'),
(3602, 3600, 'Shelf AJ1', 'Available'),
(3603, 3600, 'Shelf AJ2', 'Available'),
(3604, 3600, 'Shelf AJ2', 'Available'),
(3605, 3600, 'Shelf AJ3', 'Available'),
(3606, 3600, 'Shelf AJ3', 'Available'),
(3607, 3600, 'Shelf AJ4', 'Available'),
(3608, 3600, 'Shelf AJ4', 'Available'),
(3609, 3600, 'Shelf AJ5', 'Available'),
(3610, 3600, 'Shelf AJ5', 'Available'),
(3701, 3700, 'Shelf AK1', 'Available'),
(3702, 3700, 'Shelf AK1', 'Available'),
(3703, 3700, 'Shelf AK2', 'Available'),
(3704, 3700, 'Shelf AK2', 'Available'),
(3705, 3700, 'Shelf AK3', 'Available'),
(3706, 3700, 'Shelf AK3', 'Available'),
(3707, 3700, 'Shelf AK4', 'Available'),
(3708, 3700, 'Shelf AK4', 'Available'),
(3709, 3700, 'Shelf AK5', 'Available'),
(3710, 3700, 'Shelf AK5', 'Available'),
(3801, 3800, 'Shelf AL1', 'Available'),
(3802, 3800, 'Shelf AL1', 'Available'),
(3803, 3800, 'Shelf AL2', 'Available'),
(3804, 3800, 'Shelf AL2', 'Available'),
(3805, 3800, 'Shelf AL3', 'Available'),
(3806, 3800, 'Shelf AL3', 'Available'),
(3807, 3800, 'Shelf AL4', 'Available'),
(3808, 3800, 'Shelf AL4', 'Available'),
(3809, 3800, 'Shelf AL5', 'Available'),
(3810, 3800, 'Shelf AL5', 'Available'),
(3901, 3900, 'Shelf AM1', 'Available'),
(3902, 3900, 'Shelf AM1', 'Available'),
(3903, 3900, 'Shelf AM2', 'Available'),
(3904, 3900, 'Shelf AM2', 'Available'),
(3905, 3900, 'Shelf AM3', 'Available'),
(3906, 3900, 'Shelf AM3', 'Available'),
(3907, 3900, 'Shelf AM4', 'Available'),
(3908, 3900, 'Shelf AM4', 'Available'),
(3909, 3900, 'Shelf AM5', 'Available'),
(3910, 3900, 'Shelf AM5', 'Available'),
(4001, 4000, 'Shelf AN1', 'Available'),
(4002, 4000, 'Shelf A1', 'Available'),
(4003, 4000, 'Shelf A2', 'Available'),
(4004, 4000, 'Shelf A2', 'Available'),
(4005, 4000, 'Shelf B1', 'Available'),
(4006, 4000, 'Shelf B1', 'Available'),
(4007, 4000, 'Shelf B2', 'Available'),
(4008, 4000, 'Shelf B2', 'Available');

DROP PROCEDURE IF EXISTS GenerateBorrowRecordsBatch;
DELIMITER //

CREATE PROCEDURE GenerateBorrowRecordsBatch(IN startNum INT, IN endNum INT, IN startDate DATE)
BEGIN
    DECLARE i INT DEFAULT startNum;
    DECLARE v_copyid INT;
    DECLARE v_subid INT;
    DECLARE currentDate DATE DEFAULT startDate;
    DECLARE borrowsPerDay INT;
    DECLARE dailyBorrows INT DEFAULT 0;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_books 
    SELECT CopyID FROM bookcopies 
    WHERE Status = 'Available' 
    AND CopyID NOT IN (SELECT CopyID FROM borrowrecords WHERE Status = 'Borrowed')
    LIMIT 500;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_subs 
    SELECT SubID FROM subscribers 
    WHERE Expiration > currentDate 
    AND FreezeUntil IS NULL
    AND Status = 'Active'
    LIMIT 500;
    
    START TRANSACTION;
    
    WHILE i <= endNum AND currentDate <= CURDATE() DO
        -- Reset daily borrows counter when starting new day
        IF dailyBorrows = 0 THEN
            SET borrowsPerDay = FLOOR(RAND() * 4); -- 0-3 borrows per day
        END IF;

        SELECT SubID INTO v_subid FROM temp_subs ORDER BY RAND() LIMIT 1;
        SELECT CopyID INTO v_copyid FROM temp_books ORDER BY RAND() LIMIT 1;

        IF v_subid IS NOT NULL AND v_copyid IS NOT NULL THEN
            INSERT INTO borrowrecords 
            (CopyID, SubID, BorrowDate, ExpectedReturnDate, Status)
            VALUES 
            (v_copyid, v_subid, currentDate, 
             DATE_ADD(currentDate, INTERVAL 14 DAY), 'Borrowed');

            DELETE FROM temp_books WHERE CopyID = v_copyid;
            
            SET dailyBorrows = dailyBorrows + 1;
            SET i = i + 1;
            
            -- Move to next day after reaching borrowsPerDay
            IF dailyBorrows >= borrowsPerDay THEN
                SET currentDate = DATE_ADD(currentDate, INTERVAL 1 DAY);
                SET dailyBorrows = 0;
            END IF;
        END IF;
    END WHILE;
    
    SET @last_borrow_date = currentDate;
    
    COMMIT;
    DROP TEMPORARY TABLE IF EXISTS temp_books;
    DROP TEMPORARY TABLE IF EXISTS temp_subs;
END //

DELIMITER ;

DROP PROCEDURE IF EXISTS UpdateReturnDatesForBatch;
DELIMITER //

CREATE PROCEDURE UpdateReturnDatesForBatch(IN startRow INT, IN batchSize INT)
BEGIN
    UPDATE borrowrecords 
    SET ActualReturnDate = 
        CASE 
            WHEN RAND() <= 0.5 THEN 
                DATE_SUB(ExpectedReturnDate, INTERVAL FLOOR(RAND() * 3) DAY)
            WHEN RAND() <= 0.8 THEN 
                DATE_ADD(ExpectedReturnDate, INTERVAL FLOOR(RAND() * 7 + 1) DAY)
            ELSE 
                DATE_ADD(ExpectedReturnDate, INTERVAL FLOOR(RAND() * 7 + 8) DAY)
        END
    WHERE BorrowID >= startRow 
    AND BorrowID < (startRow + batchSize)
    AND ActualReturnDate IS NULL
    AND ExpectedReturnDate <= DATE_SUB(CURDATE(), INTERVAL 12 DAY);
    
    -- Debug output
    SELECT CONCAT('Updated rows: ', ROW_COUNT()) as DebugMessage;
END //

DELIMITER ;

-- Execute in batches
SET @current_date = '2024-01-01';

-- First batch (1-150)
CALL GenerateBorrowRecordsBatch(1, 150, @current_date);
CALL UpdateReturnDatesForBatch(1, 150);

-- Second batch (151-300)
CALL GenerateBorrowRecordsBatch(151, 300, @last_borrow_date);
CALL UpdateReturnDatesForBatch(151, 300);

-- Third batch (301-450)
CALL GenerateBorrowRecordsBatch(301, 450, @last_borrow_date);
CALL UpdateReturnDatesForBatch(301, 150);

-- Fourth batch (451-600)
CALL GenerateBorrowRecordsBatch(451, 600, @last_borrow_date);
CALL UpdateReturnDatesForBatch(451, 150);

-- Fifth batch (601-750)
CALL GenerateBorrowRecordsBatch(601, 750, @last_borrow_date);
CALL UpdateReturnDatesForBatch(601, 150);


-- Set all BookID 100 copies as borrowed
DROP PROCEDURE IF EXISTS GenerateBook100Borrows;
DELIMITER //

CREATE PROCEDURE GenerateBook100Borrows()
BEGIN
    DECLARE v_subid INT;
    DECLARE v_copyid INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE copy_cursor CURSOR FOR 
        SELECT CopyID 
        FROM bookcopies 
        WHERE BookID = 100 
        AND Status = 'Available';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN copy_cursor;
    
    read_loop: LOOP
        FETCH copy_cursor INTO v_copyid;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Get random eligible subscriber
        SELECT SubID INTO v_subid 
        FROM subscribers 
        WHERE Expiration > CURDATE()
        AND (FreezeUntil IS NULL OR FreezeUntil < CURDATE())
        ORDER BY RAND() LIMIT 1;

        IF v_subid IS NOT NULL THEN
            -- Insert borrow record
            INSERT INTO borrowrecords 
            (CopyID, SubID, BorrowDate, ExpectedReturnDate, Status)
            VALUES 
            (v_copyid, v_subid, CURDATE(), 
             DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'Borrowed');

            -- Update copy status
            UPDATE bookcopies 
            SET Status = 'Borrowed'
            WHERE CopyID = v_copyid;
        END IF;
    END LOOP;

    CLOSE copy_cursor;
END //

DELIMITER ;

-- Execute the procedure
CALL GenerateBook100Borrows();


-- Temporarily change the schedule to every minute for testing
ALTER EVENT update_overdue_status
ON SCHEDULE EVERY 1 MINUTE;
ALTER EVENT apply_penalties
ON SCHEDULE EVERY 1 MINUTE;
ALTER EVENT unfreeze_subscribers
ON SCHEDULE EVERY 1 MINUTE;
ALTER EVENT notify_day_before_due_date
ON SCHEDULE EVERY 1 MINUTE;

-- Revert back to daily schedule after testing
ALTER EVENT update_overdue_status
ON SCHEDULE EVERY 1 DAY;
ALTER EVENT apply_penalties
ON SCHEDULE EVERY 1 DAY;
ALTER EVENT unfreeze_subscribers
ON SCHEDULE EVERY 1 DAY;
ALTER EVENT notify_day_before_due_date
ON SCHEDULE EVERY 1 DAY;

