SET NOCOUNT ON;
GO

USE HealthCaredb;
GO


GRANT CONTROL ON DATABASE::HealthCaredb TO public_health_nurse;
GO

--EXECUTE 

DECLARE @sqlcommand varchar (1000)
DECLARE @columnList varchar(75)
DECLARE @BloodType nvarchar(10) 
SET @columnlist= 'PatientName, gender , InsuranceNum'
SET @BloodType='''A'''
SET @sqlcommand='SELECT ' +@columnlist + ' FROM Patient_Info WHERE BloodType= ' +@BloodType
EXEC(@sqlcommand)
GO

-- retrieve high amount of data from a sensitive table

SELECT InsuranceNum, PatientName AS Name FROM Patient_Info ORDER BY Name ASC;
GO
