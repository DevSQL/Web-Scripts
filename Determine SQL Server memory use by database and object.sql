--http://www.mssqltips.com/sqlservertip/2393/determine-sql-server-memory-use-by-database-and-object/

/*
A Dynamic Management View (DMV) introduced in SQL Server 2005, 
called sys.dm_os_buffer_descriptors, contains a row for every 
page that has been cached in the buffer pool. Using this DMV, 
you can quickly determine which database(s) are utilizing the 
majority of your buffer pool memory. Once you have identified 
the databases that are occupying much of the buffer pool, you 
can drill into them individually. In the following query, I first 
find out exactly how big the buffer pool currently is (from the 
DMV sys.dm_os_performance_counters), allowing me to calculate the 
percentage of the buffer pool being used by each database: 
*/

DECLARE @total_buffer INT;

SELECT @total_buffer = cntr_value
   FROM sys.dm_os_performance_counters 
   WHERE RTRIM([object_name]) LIKE '%Buffer Manager'
   AND counter_name = 'Total Pages';

;WITH src AS
(
   SELECT 
       database_id, db_buffer_pages = COUNT_BIG(*)
       FROM sys.dm_os_buffer_descriptors
       --WHERE database_id BETWEEN 5 AND 32766
       GROUP BY database_id
)
SELECT
   [db_name] = CASE [database_id] WHEN 32767 
       THEN 'Resource DB' 
       ELSE DB_NAME([database_id]) END,
   db_buffer_pages,
   db_buffer_MB = db_buffer_pages / 128,
   db_buffer_percent = CONVERT(DECIMAL(6,3), 
       db_buffer_pages * 100.0 / @total_buffer)
FROM src
ORDER BY db_buffer_MB DESC; 



--**********************


-- 2.- Luego, se analiza la base de datos que tiene mas alto
--     db_buffer_percent

USE Custodia_Factoring;
GO

;WITH src AS
(
   SELECT
       [Object] = o.name,
       [Type] = o.type_desc,
       [Index] = COALESCE(i.name, ''),
       [Index_Type] = i.type_desc,
       p.[object_id],
       p.index_id,
       au.allocation_unit_id
   FROM
       sys.partitions AS p
   INNER JOIN
       sys.allocation_units AS au
       ON p.hobt_id = au.container_id
   INNER JOIN
       sys.objects AS o
       ON p.[object_id] = o.[object_id]
   INNER JOIN
       sys.indexes AS i
       ON o.[object_id] = i.[object_id]
       AND p.index_id = i.index_id
   WHERE
       au.[type] IN (1,2,3)
       AND o.is_ms_shipped = 0
)
SELECT
   src.[Object],
   src.[Type],
   src.[Index],
   src.Index_Type,
   buffer_pages = COUNT_BIG(b.page_id),
   buffer_mb = COUNT_BIG(b.page_id) / 128
FROM
   src
INNER JOIN
   sys.dm_os_buffer_descriptors AS b
   ON src.allocation_unit_id = b.allocation_unit_id
WHERE
   b.database_id = DB_ID()
GROUP BY
   src.[Object],
   src.[Type],
   src.[Index],
   src.Index_Type
ORDER BY
   buffer_pages DESC;
