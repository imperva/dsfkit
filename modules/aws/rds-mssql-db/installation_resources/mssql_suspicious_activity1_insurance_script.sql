SET NOCOUNT ON;
GO

USE Insurancedb;
GO

GRANT CONTROL ON DATABASE::Insurancedb TO Broker;
GO

--EXECUTE 

DECLARE @sqlcommand varchar (1000)
DECLARE @columnList varchar(75)
DECLARE @PolicyType nvarchar(50) 
SET @columnlist= 'StartMonth, StartYear, PolicyNumber'
SET @PolicyType='''Tenant'''
SET @sqlcommand='SELECT ' +@columnlist + ' FROM InsuranceInfo WHERE PolicyType= ' +@PolicyType
EXEC(@sqlcommand)
GO

-- retrieve high amount of data from a sensitive table

SELECT PolicyNumber,StartYear AS Start FROM InsuranceInfo ORDER BY Start ASC;
GO
