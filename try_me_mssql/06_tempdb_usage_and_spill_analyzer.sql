/* ===============================================================================
   Author       : Senior SQL Server DBA / Software Architect
   Description  : TempDB veritabanı üzerindeki sayfa tahsislerini (Internal/User Objects)
                  analiz eder. TempDB'yi en çok tüketen aktif oturumları ve 
                  dosya seviyesindeki I/O darboğazlarını raporlar.
   Target Engine: SQL Server 2012 ve üzeri
   =============================================================================== */

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF OBJECT_ID('tempdb..#TempDbUsageReport') IS NOT NULL
    DROP TABLE #TempDbUsageReport;

CREATE TABLE #TempDbUsageReport (
    SPID                    INT,
    LoginName               NVARCHAR(128),
    HostName                NVARCHAR(128),
    ProgramName             NVARCHAR(128),
    DatabaseName            NVARCHAR(128),
    UserObjectsAllocMB      NUMERIC(18, 2),
    UserObjectsDeallocMB    NUMERIC(18, 2),
    InternalObjectsAllocMB  NUMERIC(18, 2),
    InternalObjectsDeallocMB NUMERIC(18, 2),
    TotalNetAllocatedMB     NUMERIC(18, 2),
    ActiveStatementText     NVARCHAR(MAX)
);

INSERT INTO #TempDbUsageReport
SELECT 
    s.session_id AS SPID,
    s.login_name AS LoginName,
    s.host_name AS HostName,
    s.program_name AS ProgramName,
    DB_NAME(r.database_id) AS DatabaseName,
    
    -- Sayfa başı 8 KB hesabı üzerinden MB dönüşümü
    CAST((su.user_objects_alloc_page_count * 8.0) / 1024.0 AS NUMERIC(18, 2)) AS UserObjectsAllocMB,
    CAST((su.user_objects_dealloc_page_count * 8.0) / 1024.0 AS NUMERIC(18, 2)) AS UserObjectsDeallocMB,
    CAST((su.internal_objects_alloc_page_count * 8.0) / 1024.0 AS NUMERIC(18, 2)) AS InternalObjectsAllocMB,
    CAST((su.internal_objects_dealloc_page_count * 8.0) / 1024.0 AS NUMERIC(18, 2)) AS InternalObjectsDeallocMB,
    
    -- Net Tüketim (Tahsis Edilen - Serbest Bırakılan)
    CAST((
        (su.user_objects_alloc_page_count - su.user_objects_dealloc_page_count +
         su.internal_objects_alloc_page_count - su.internal_objects_dealloc_page_count) * 8.0
    ) / 1024.0 AS NUMERIC(18, 2)) AS TotalNetAllocatedMB,
    
    ISNULL(st.text, N'-- Sessiz / Aktif Sorgu Yok --') AS ActiveStatementText
FROM sys.dm_db_session_space_usage su
INNER JOIN sys.dm_exec_sessions s ON su.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE s.is_user_process = 1
  AND (su.user_objects_alloc_page_count + su.internal_objects_alloc_page_count) > 0;

-- TempDB'yi En Çok Tüketen Sorguların Çıktılanması
SELECT TOP 20
    SPID,
    LoginName,
    HostName,
    ProgramName,
    DatabaseName,
    UserObjectsAllocMB AS [User Objects (MB)],
    InternalObjectsAllocMB AS [Internal Objects / Sort/Hash (MB)],
    TotalNetAllocatedMB AS [Net Active Usage (MB)],
    ActiveStatementText
FROM #TempDbUsageReport
ORDER BY TotalNetAllocatedMB DESC;