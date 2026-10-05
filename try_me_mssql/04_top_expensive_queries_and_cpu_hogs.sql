/* ===============================================================================
   Author       : Senior SQL Server DBA / Software Architect
   Description  : Plan Cache üzerindeki en yüksek CPU harcayan, en çok Logical I/O 
                  yapan ve en sık çalışan top sorguları nokta atışı tespit eder.
   Target Engine: SQL Server 2012 ve üzeri
   =============================================================================== */

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT TOP 15
    DB_NAME(st.dbid) AS DatabaseName,
    qs.execution_count AS ExecutionCount,
    
    -- Ortalama CPU Süresi (Milisaniye)
    CAST((qs.total_worker_time / qs.execution_count) / 1000.0 AS NUMERIC(12,2)) AS [Avg CPU (ms)],
    
    -- Ortalama Toplam Çalışma Süresi (Milisaniye)
    CAST((qs.total_elapsed_time / qs.execution_count) / 1000.0 AS NUMERIC(12,2)) AS [Avg Duration (ms)],
    
    -- Ortalama Mantıksal Disk Okuması (Sayfa Büyüklüğü * 8KB)
    (qs.total_logical_reads / qs.execution_count) AS [Avg Logical Reads (Pages)],
    CAST(((qs.total_logical_reads / qs.execution_count) * 8.0) / 1024.0 AS NUMERIC(10,2)) AS [Avg Read Size (MB)],
    
    -- Bütün SP/Batch içinden SADECE ilgili yavaş çalışan SQL Cümlesini Ayrıştırma
    SUBSTRING(
        st.text, 
        (qs.statement_start_offset / 2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset) / 2) + 1
    ) AS QueryStatementText,
    
    qp.query_plan AS GraphicalExecutionPlan -- SSMS'te tıklanabilir XML Plan linki

FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE st.dbid > 4 -- System DB'ler hariç
ORDER BY qs.total_worker_time DESC; -- En yüksek Toplam CPU harcayana göre sırala