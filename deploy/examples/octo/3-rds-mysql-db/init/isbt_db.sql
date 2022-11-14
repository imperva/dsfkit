SET NAMES latin1;
SET FOREIGN_KEY_CHECKS = 0;

use isbt_db;

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` varchar(255) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(40) NOT NULL,
  `first_name` varchar(254) NOT NULL,
  `last_name` varchar(254) NOT NULL,
  `email` varchar(45) NOT NULL,
  `phone_num` varchar(35) DEFAULT NULL,
  `address` varchar(80) NOT NULL,
  `city` char(255) DEFAULT NULL,
  `state` char(2) DEFAULT NULL,
  `zip` int(5) DEFAULT NULL,
  `country` char(3) DEFAULT NULL,
  `cc_number` char(16) NOT NULL,
  `cc_date` char(5) NOT NULL,
  `role` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK_ob8kqyqqgmefl0aco34akdtpe` (`email`),
  UNIQUE KEY `UK_a3imlf41l37utmxiquukk8ajc` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1006 DEFAULT CHARSET=latin1;

LOCK TABLES `users` WRITE;
INSERT INTO `users` (id,user_id,username,password,first_name,last_name,email,phone_num,address,city,state,zip,country,cc_number,cc_date,role) VALUES
  (1001,'99b4bb92-a909-44c5-9887-8428b7227eb3','ba@imperva.com','webco123','Brian','Anderson','ba@imperva.com','1324745798','3400 Bridge Parkway','Redwood City','CA',94065,'US','4012888888881881','12/12','ROLE_ADMIN'),
  (1002,'7a117e5e-937b-4fe1-a739-50d23c933083','joe.moore@imperva.com','webco123','Joe','Moore','joe.moore@imperva.com','1368210155','3400 Bridge Parkway','Redwood City','CA',94065,'US','4012888888881881','12/12','ROLE_ADMIN'),
  (1003,'4130dff8-7462-44be-a1a5-0ad155609aea','peter.klimek@imperva.com','webco123','Peter','Klimek','peter.klimek@imperva.com','1189119001','3400 Bridge Parkway','Redwood City','CA',94065,'US','4012888888881881','12/12','ROLE_ADMIN'),
  (1004,'00c18d41-97ff-4dd2-a838-c24fbb07d297','craig.burlingame@imperva.com','webco123','Craig','Burlingame','craig.burlingame@imperva.com','1215789568','3400 Bridge Parkway','Redwood City','CA',94065,'US','4012888888881881','12/12','ROLE_ADMIN'),
  (1005,'25bfdabe-aafd-45aa-81a0-0789a3657da7','kunal.anand@imperva.com','webco123','Kunal','Anand','kunal.anand@imperva.com','1051660938','3400 Bridge Parkway','Redwood City','CA',94065,'US','4012888888881881','12/12','ROLE_ADMIN');
UNLOCK TABLES;

DROP TABLE IF EXISTS `accounts`;
CREATE TABLE `accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_type` varchar(16) NOT NULL,
  `status` varchar(16) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `name` varchar(128) NOT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'USD',
  `balance` float NOT NULL DEFAULT '0',
  `available_balance` float DEFAULT NULL,
  `prior_balance` float DEFAULT NULL,
  `payment_due_date` date DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=100019 DEFAULT CHARSET=latin1;

LOCK TABLES `accounts` WRITE;
INSERT INTO `accounts` (id,account_type,status,user_id,name,currency,balance,available_balance,prior_balance,payment_due_date) VALUES
  (100001,'Checking','Open','99b4bb92-a909-44c5-9887-8428b7227eb3','Performance Checking Account','USD',16384.4,16384.4,NULL,NULL),
  (100002,'Savings','Open','99b4bb92-a909-44c5-9887-8428b7227eb3','High Yield Savings Account','USD',187315,187315,NULL,NULL),
  (100003,'Credit Card','Open','99b4bb92-a909-44c5-9887-8428b7227eb3','Anywhere MasterCard','USD',912.14,49087.9,2172.18,'2019-08-31'),
  (100004,'Checking','Open','7a117e5e-937b-4fe1-a739-50d23c933083','Performance Checking Account','USD',38712.1,35712.1,NULL,NULL),
  (100005,'Savings','Open','7a117e5e-937b-4fe1-a739-50d23c933083','High Yield Savings Account','USD',419258,419258,NULL,NULL),
  (100006,'Credit Card','Open','7a117e5e-937b-4fe1-a739-50d23c933083','AmEx Black Card','USD',0,250000,14912.1,'2019-08-31'),
  (100007,'Credit Card','Open','7a117e5e-937b-4fe1-a739-50d23c933083','Anywhere MasterCard','USD',0,75000,0,'2019-08-31'),
  (100008,'Checking','Open','4130dff8-7462-44be-a1a5-0ad155609aea','Performance Checking Account','USD',712.16,712.16,NULL,NULL),
  (100009,'Savings','Open','4130dff8-7462-44be-a1a5-0ad155609aea','High Yield Savings Account','USD',3869.09,3869.09,NULL,NULL),
  (100010,'Credit Card','Open','4130dff8-7462-44be-a1a5-0ad155609aea','Anywhere MasterCard','USD',6785.06,13214.9,9144.38,'2019-08-31'),
  (100011,'Checking','Open','00c18d41-97ff-4dd2-a838-c24fbb07d297','Performance Checking Account','USD',8112.17,7112.17,NULL,NULL),
  (100012,'Savings','Open','00c18d41-97ff-4dd2-a838-c24fbb07d297','High Yield Savings Account','USD',46758.1,45768.1,NULL,NULL),
  (100013,'Credit Card','Open','00c18d41-97ff-4dd2-a838-c24fbb07d297','Anywhere MasterCard','USD',1406.72,33593.3,654.12,'2019-08-31'),
  (100014,'Credit Card','Open','00c18d41-97ff-4dd2-a838-c24fbb07d297','J. Peterman Corporate Card','USD',17212.1,82787.9,1789.21,'2019-08-31'),
  (100015,'Checking','Open','25bfdabe-aafd-45aa-81a0-0789a3657da7','Performance Checking Account','USD',38712.1,35712.1,NULL,NULL),
  (100016,'Savings','Open','25bfdabe-aafd-45aa-81a0-0789a3657da7','High Yield Savings Account','USD',419258,419258,NULL,NULL),
  (100017,'Credit Card','Open','25bfdabe-aafd-45aa-81a0-0789a3657da7','Imperva Corporate Black Card','USD',0,250000,14912.1,'2018-08-31'),
  (100018,'Credit Card','Open','25bfdabe-aafd-45aa-81a0-0789a3657da7','Anywhere MasterCard','USD',0,75000,0,'2018-08-31');
UNLOCK TABLES;

DROP TABLE IF EXISTS `transactions`;
CREATE TABLE `transactions` (
  `id` varchar(255) NOT NULL,
  `account_id` int(11) NOT NULL,
  `tx_type` varchar(12) NOT NULL,
  `tx_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `description` varchar(255) DEFAULT NULL,
  `details` text,
  `currency` varchar(3) NOT NULL DEFAULT 'USD',
  `amount` float NOT NULL,
  `status` varchar(16) DEFAULT NULL,
  `dispute_reason` varchar(32) DEFAULT NULL,
  `dispute_details` varchar(255) DEFAULT NULL,
  KEY `id_idx` (`account_id`),
  CONSTRAINT `account_id_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

LOCK TABLES `transactions` WRITE;
INSERT INTO `transactions` (id,account_id,tx_type,tx_date,description,details,currency,amount,status,dispute_reason,dispute_details) VALUES
  ('6O640X-5ZU1EH',100001,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100001,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100001,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100002,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100002,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100002,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100003,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100003,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100003,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100004,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100004,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100004,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100005,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100005,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100005,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100006,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100006,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100006,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100007,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100007,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100007,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100008,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100008,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100008,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100009,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100009,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100009,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100010,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100010,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100010,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100011,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100011,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100011,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100012,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100012,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100012,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100013,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100013,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100013,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100014,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100014,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100014,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100015,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100015,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100015,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100016,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100016,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100016,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100017,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100017,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100017,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL),
  ('6O640X-5ZU1EH',100018,'Charge','2019-07-17 14:12:07','Barney''s New York',NULL,'USD',9487.27,'Posted',NULL,NULL),
  ('S7KBMZ-FJ6TQS',100018,'Charge','2019-07-17 16:18:32','Puta Mayo',NULL,'USD',338.14,'Posted',NULL,NULL),
  ('DMBP0B-ZDUGDI',100018,'Charge','2019-07-21 08:31:46','Reimenschneider Meats',NULL,'USD',31.81,'Posted',NULL,NULL);
  
UNLOCK TABLES;

DROP TABLE IF EXISTS `balance_transfers`;
CREATE TABLE `balance_transfers` (
  `id` varchar(255) NOT NULL,
  `source_account_id` int(11) NOT NULL,
  `target_account_id` int(11) NOT NULL,
  `direction` varchar(12) NOT NULL,
  `transfer_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `currency` varchar(3) NOT NULL DEFAULT 'USD',
  `amount` float NOT NULL,
  KEY `source_account_id` (`source_account_id`),
  KEY `target_account_id` (`target_account_id`),
  CONSTRAINT `balance_transfers_ibfk_1` FOREIGN KEY (`source_account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `balance_transfers_ibfk_2` FOREIGN KEY (`target_account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

LOCK TABLES `balance_transfers` WRITE;
INSERT INTO `balance_transfers` VALUES ('DMBP0B-ZDUGDI',100003,100014,'TRANSFER_TO','2018-11-14 13:31:46','USD',125.81);
UNLOCK TABLES;

SET FOREIGN_KEY_CHECKS = 1;
