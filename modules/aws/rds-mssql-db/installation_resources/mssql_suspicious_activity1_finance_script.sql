SET NOCOUNT ON;
GO

USE financedb;
GO

GRANT CONTROL ON DATABASE::financedb TO Teller;
GO

--EXECUTE 

DECLARE @sqlcommand varchar (1000)
DECLARE @columnList varchar(75)
DECLARE @CardType nvarchar(50) 
SET @columnlist= 'ExpMonth, ExpYear, CardNumber'
SET @CardType='''Visa'''
SET @sqlcommand='SELECT ' +@columnlist + ' FROM CreditCard WHERE CardType= ' +@CardType
EXEC(@sqlcommand)
GO

-- retrieve high amount of data from a sensitive table

SELECT CardNumber,ExpYear AS Expire FROM CreditCard ORDER BY Expire ASC;
GO
