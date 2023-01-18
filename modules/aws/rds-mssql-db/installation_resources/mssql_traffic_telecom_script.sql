SET NOCOUNT ON;
GO

USE telecomdb;
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM NetworkUsers WHERE UserName LIKE '%John%' AND PlanType='Home Security';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM NetworkUsers WHERE UserName LIKE '%John%' AND PlanType='Home Security';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM NetworkUsers WHERE UserName LIKE '%John%' AND PlanType='Home Security';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM NetworkUsers WHERE UserName LIKE '%John%' AND PlanType='Home Security';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM NetworkUsers WHERE UserName LIKE '%John%' AND PlanType='Home Security';
	SET @count=@count +1
END
GO

CREATE TABLE Account (AccountId int identity not null, Avail_Balance float, Open_date datetime not null, Status varchar(10), Cust_id int, primary key (AccountId));
GO

INSERT INTO Account VALUES(12478.32, '06.23.2011', 'active', 25);
GO

INSERT INTO Account VALUES(567.22, '11.12.2019', 'suspended', 30);
GO

UPDATE Account SET Avail_Balance   = Avail_Balance + 2 * Avail_Balance / 100 WHERE Open_date='06.23.2011';
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

CREATE LOGIN supervisor with password = 'sonarw321';
GO

CREATE USER supervisor from login supervisor;
GO

GRANT select,insert to supervisor;
GO

REVOKE select from supervisor;
GO

--cleanup

DROP TABLE Account;
GO

DROP user supervisor;
GO

DROP login supervisor;
GO
