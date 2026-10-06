/* ===============================================================================
   Author       : Senior SQL Server DBA / Software Architect
   Description  : Canlı sistemde anlık kilitlenmeleri (Blocking) ve Deadlock 
                  riski taşıyan kilit zincirini hiyerarşik olarak analiz eder.
                  Kök kilitleyiciyi (Head Blocker) ve etkilenen SPID'leri çıkarır.
   Target Engine: SQL Server 2012 ve üzeri
   =============================================================================== */

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF OBJECT_ID('tempdb..#BlockingChain') IS NOT NULL
    DROP TABLE #BlockingChain;

SELECT 
    r.session_id AS SPID,
    r.blocking_session_id AS BlockerSPID,
    DB_NAME(r.database_id) AS DatabaseName,
    s.status AS SessionStatus,
    r.status AS RequestStatus,
    r.command AS CommandType,
    r.wait_type AS WaitType,
    CAST(r.wait_time / 1000.0 AS NUMERIC(18, 2)) AS WaitTimeSeconds,
    s.cpu_time AS CpuTimeMs,
    s.logical_reads AS LogicalReads,
    s.host_name AS HostName,
    s.program_name AS ProgramName,
    s.login_name AS LoginName,
    
    -- Çalıştırılan Anlık T-SQL Cümlesi
    SUBSTRING(st.text, (r.statement_start_offset/2)+1, 
        ((CASE r.statement_end_offset 
            WHEN -1 THEN DATALENGTH(st.text) 
            ELSE r.statement_end_offset 
          END - r.statement_start_offset)/2) + 1) AS ExecutingStatement,
          
    st.text AS FullBatchText,
    qp.query_plan AS ExecutionPlan
FROM sys.dm_exec_requests r
INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) qp
WHERE r.session_id <> @@SPID 
  AND (
        r.blocking_session_id <> 0 
        OR r.session_id IN (SELECT DISTINCT blocking_session_id FROM sys.dm_exec_requests WHERE blocking_session_id <> 0)
      )
INTO #BlockingChain;

-- Raporlama: Head Blocker ve Kilitlenen Alt Sorguların Listelenmesi
SELECT 
    CASE 
        WHEN BlockerSPID = 0 THEN 'HEAD BLOCKER (Kök Kilitleyici)'
        ELSE 'BLOCKED (Kilitlenen)'
    END AS NodeRole,
    SPID,
    BlockerSPID,
    DatabaseName,
    WaitType,
    WaitTimeSeconds,
    CommandType,
    ExecutingStatement,
    HostName,
    ProgramName,
    LoginName,
    ExecutionPlan
FROM #BlockingChain
ORDER BY 
    BlockerSPID ASC, 
    WaitTimeSeconds DESC;