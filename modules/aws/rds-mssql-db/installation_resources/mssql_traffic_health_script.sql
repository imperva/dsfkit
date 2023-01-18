SET NOCOUNT ON;
GO

USE HealthCaredb;
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
  SELECT TOP 1 * FROM Patient_Info WHERE PatientName LIKE '%John%' AND BloodType='O';
  SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
  SELECT TOP 1 * FROM Patient_Info WHERE PatientName LIKE '%John%' AND BloodType='O';
  SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
  SELECT TOP 1 * FROM Patient_Info WHERE PatientName LIKE '%John%' AND BloodType='O';
  SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
  SELECT TOP 1 * FROM Patient_Info WHERE PatientName LIKE '%John%' AND BloodType='O';
  SET @count=@count +1
END
GO

DECLARE @count AS INT
SET @count=1
WHILE ( @count <= 100)
BEGIN
  SELECT TOP 1 * FROM Patient_Info WHERE PatientName LIKE '%John%' AND BloodType='O';
  SET @count=@count +1
END
GO

CREATE TABLE Medication (
  Code INTEGER PRIMARY KEY NOT NULL,
  Name TEXT NOT NULL,
  Brand TEXT NOT NULL,
  StockAmount INT,
  Description TEXT NOT NULL
);
GO

INSERT INTO Medication VALUES(1,'Procrastin-X','X',5,'N/A');
INSERT INTO Medication VALUES(2,'Thesisin','Foo Labs',22,'N/A');
INSERT INTO Medication VALUES(3,'Awakin','Bar Laboratories',68,'N/A');
INSERT INTO Medication VALUES(4,'Crescavitin','Baz Industries',1,'N/A');
INSERT INTO Medication VALUES(5,'Melioraurin','Snafu Pharmaceuticals',12,'N/A');
GO

UPDATE Medication SET StockAmount=(StockAmount + 2) WHERE Code=4;
GO

DELETE FROM Medication WHERE Brand LIKE '%The%';
GO

ALTER TABLE Medication ADD Expiredate date;
GO

ALTER TABLE Medication
ALTER COLUMN Expiredate datetime;
GO

ALTER TABLE Medication
DROP COLUMN Expiredate;
GO

CREATE LOGIN psychiatrist with password = 'sonarw321';
GO

CREATE USER psychiatrist from login psychiatrist;
GO

GRANT select,insert to psychiatrist;
GO

REVOKE select from psychiatrist;
GO

--cleanup

DROP TABLE Medication;
GO

DROP user psychiatrist;
GO

DROP login psychiatrist;
GO
