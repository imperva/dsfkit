SET NOCOUNT ON;
GO

USE Insurancedb;
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM InsuranceInfo WHERE cust_name LIKE '%John%' AND PolicyType='Life';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM InsuranceInfo WHERE cust_name LIKE '%John%' AND PolicyType='Life';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM InsuranceInfo WHERE cust_name LIKE '%John%' AND PolicyType='Life';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM InsuranceInfo WHERE cust_name LIKE '%John%' AND PolicyType='Life';
	SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
	SELECT TOP 1 * FROM InsuranceInfo WHERE cust_name LIKE '%John%' AND PolicyType='Life';
	SET @count=@count +1
END
GO

CREATE TABLE Policy (PolicyId int identity not null, Coverage float, Open_date datetime not null, Status varchar(10), Cust_id int, primary key (PolicyId));
GO

INSERT INTO Policy VALUES(12478.32, '06.23.2011', 'active', 25);
GO

INSERT INTO Policy VALUES(567.22, '11.12.2019', 'suspended', 30);
GO

UPDATE Policy SET Coverage   = Coverage + 2 * Coverage / 100 WHERE Open_date='06.23.2011';
GO

SELECT Sum(Coverage)  As Sum_Coverage
From Policy Where Cust_Id < 35;
GO

DELETE FROM Policy WHERE Status='suspended';
GO

ALTER TABLE Policy ADD LastActivity date;
GO

ALTER TABLE Policy
ALTER COLUMN LastActivity datetime;
GO

ALTER TABLE Policy
DROP COLUMN LastActivity;
GO

CREATE LOGIN Accountant with password = 'sonarw321';
GO

CREATE USER Accountant from login Accountant;
GO

GRANT select,insert to Accountant;
GO

REVOKE select from Accountant;
GO

--cleanup

DROP TABLE Policy;
GO

DROP user Accountant;
GO

DROP login Accountant;
GO
