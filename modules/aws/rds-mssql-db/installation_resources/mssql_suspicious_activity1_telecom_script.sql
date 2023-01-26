SET NOCOUNT ON;
GO

USE telecomdb;
GO

GRANT CONTROL ON DATABASE::telecomdb TO Technician;
GO

--EXECUTE 

DECLARE @sqlcommand varchar (1000)
DECLARE @columnList varchar(75)
DECLARE @PlanType nvarchar(50) 
SET @columnlist= 'UserName, Password, IPV4'
SET @PlanType='''TV'''
SET @sqlcommand='SELECT ' +@columnlist + ' FROM NetworkUsers WHERE PlanType= ' +@PlanType
EXEC(@sqlcommand)
GO

-- retrieve high amount of data from a sensitive table

SELECT IPV4,UserName AS Client FROM NetworkUsers ORDER BY Client ASC;
GO
