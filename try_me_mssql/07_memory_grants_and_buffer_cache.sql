/* ===============================================================================
   Author       : Senior SQL Server DBA / Software Architect
   Description  : 1. Buffer Pool (RAM) üzerinde en çok alan kaplayan tabloları bulur.
                  2. 'RESOURCE_SEMAPHORE' bekleyerek bellek yetersizliğinden 
                     kuyruğa giren sorguları (Memory Grant Waiters) raporlar.
   Target Engine: SQL Server 2012 ve üzeri
   =============================================================================== */

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- 1. Veritabanı ve Tablo Bazlı Buffer Cache (RAM) Dağılımı
IF OBJECT_ID('tempdb..#BufferPoolReport') IS NOT NULL
    DROP TABLE #BufferPoolReport;

CREATE TABLE #BufferPoolReport (
    DatabaseName NVARCHAR(128),
    SchemaName   NVARCHAR(128),
    TableName    NVARCHAR(128),
    IndexName    NVARCHAR(128),
    CachedMB     NUMERIC(18, 2),
    BufferPages  BIGINT
);

DECLARE @DbName NVARCHAR(128);
DECLARE @Sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT name 
FROM sys.databases 
WHERE database_id > 4 AND state_desc = 'ONLINE' AND HAS_DBACCESS(name) = 1;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @DbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Sql = N'
    USE ' + QUOTENAME(@DbName) + N';

    INSERT INTO #BufferPoolReport
    SELECT TOP 10
        DB_NAME() AS DatabaseName,
        s.name AS SchemaName,
        t.name AS TableName,
        ISNULL(i.name, ''HEAP'') AS IndexName,
        CAST(COUNT(*) * 8.0 / 1024.0 AS NUMERIC(18,2)) AS CachedMB,
        COUNT(*) AS BufferPages
    FROM sys.dm_os_buffer_descriptors b
    INNER JOIN sys.allocation_units a ON b.allocation_unit_id = a.allocation_unit_id
    INNER JOIN sys.partitions p ON a.container_id = p.hobt_id
    INNER JOIN sys.tables t ON p.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
    WHERE b.database_id = DB_ID()
      AND t.is_ms_shipped = 0
    GROUP BY s.name, t.name, i.name
    ORDER BY COUNT(*) DESC;
    ';

    BEGIN TRY
        EXEC sp_executesql @Sql;
    END TRY
    BEGIN CATCH
        -- Yetki veya veritabanı durum hatalarını pas geç
    END CATCH;

    FETCH NEXT FROM db_cursor INTO @DbName;
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Rapor 1: RAM'de En Çok Yer Kaplayan İlk 20 Nesne
SELECT TOP 20 
    DatabaseName, SchemaName, TableName, IndexName, CachedMB AS [RAM Usage (MB)], BufferPages
FROM #BufferPoolReport
ORDER BY CachedMB DESC;

-- Rapor 2: Anlık Bellek Tahsisi Bekleyen Sorgular (Memory Grant Queue)
SELECT 
    mg.session_id AS SPID,
    CAST(mg.requested_memory_kb / 1024.0 AS NUMERIC(18,2)) AS RequestedMemoryMB,
    CAST(mg.granted_memory_kb / 1024.0 AS NUMERIC(18,2)) AS GrantedMemoryMB,
    mg.is_request_granted AS IsGranted,
    mg.timeout_sec AS TimeoutSeconds,
    st.text AS ExecutingQuery
FROM sys.dm_exec_query_memory_grants mg
CROSS APPLY sys.dm_exec_sql_text(mg.sql_handle) st
ORDER BY mg.requested_memory_kb DESC;