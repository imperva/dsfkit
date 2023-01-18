SET NOCOUNT ON;
GO

USE telecomdb;
GO

--returns all of the user tables that don't have a primary key

SELECT SCHEMA_NAME(schema_id) AS schema_name
    ,name AS table_name
FROM sys.tables
WHERE OBJECTPROPERTY(object_id,'TableHasPrimaryKey') = 0
ORDER BY schema_name, table_name;
GO

-- shows how related temporal data can be exposed

SELECT T1.object_id, T1.name as TemporalTableName, SCHEMA_NAME(T1.schema_id) AS TemporalTableSchema,
T2.name as HistoryTableName, SCHEMA_NAME(T2.schema_id) AS HistoryTableSchema,
T1.temporal_type_desc
FROM sys.tables T1
LEFT JOIN sys.tables T2
ON T1.history_table_id = T2.object_id
ORDER BY T1.temporal_type desc
GO

-- failed query no permmissions 

SELECT resource_type,spid,login_time,status,hostname,program_name,nt_domain,nt_username,loginame
FROM sys.dm_tran_locks dl
JOIN sys.sysprocesses sp on dl.request_session_id = sp.spid
GO

-- Lists all users in a database, with their rights

SELECT  princ.name
,       princ.type_desc
,       perm.permission_name
,       perm.state_desc
,       perm.class_desc
,       object_name(perm.major_id)
FROM    sys.database_principals princ
LEFT JOIN
        sys.database_permissions perm
ON      perm.grantee_principal_id = princ.principal_id
GO

-- query for table-columns that have a masking function applied to them

SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl   
    ON c.[object_id] = tbl.[object_id]  
WHERE is_masked = 1;
GO
