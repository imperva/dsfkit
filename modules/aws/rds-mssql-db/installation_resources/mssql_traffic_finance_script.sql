SET NOCOUNT ON;
GO

USE financedb;
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM CreditCard WHERE Name LIKE '%John%' AND CardType='Discover';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM CreditCard WHERE Name LIKE '%John%' AND CardType='Discover';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM CreditCard WHERE Name LIKE '%John%' AND CardType='Discover';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM CreditCard WHERE Name LIKE '%John%' AND CardType='Discover';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM CreditCard WHERE Name LIKE '%John%' AND CardType='Discover';
	SET @count=@count +1
END
GO

CREATE TABLE Account (AccountId int identity not null, Avail_Balance float, Open_date datetime not null, Status varchar(10), Cust_id int, primary key (AccountId));
GO

INSERT INTO Account VALUES(12478.32, '06.23.2011', 'active', 25);
GO

INSERT INTO Account VALUES(567.22, '11.12.2019', 'suspended', 30);
GO

UPDATE Account SET Avail_Balance = Avail_Balance + 2 * Avail_Balance / 100 WHERE Open_date='06.23.2011';
GO

SELECT Sum(Avail_Balance)  As Sum_Avail_Balance
From Account Where Cust_Id < 1;
GO

DELETE FROM Account WHERE Status='suspended';
GO

ALTER TABLE Account ADD LastActivity date;
GO

ALTER TABLE Account
ALTER COLUMN LastActivity datetime;
GO

ALTER TABLE Account
DROP COLUMN LastActivity;
GO

CREATE LOGIN credit_analyst with password = 'sonarw321';
GO

CREATE USER credit_analyst from login credit_analyst;
GO

GRANT select,insert to credit_analyst;
GO

REVOKE select from credit_analyst;
GO

DROP TABLE Account;
GO

DROP USER credit_analyst;
GO

DROP LOGIN credit_analyst;
GO
