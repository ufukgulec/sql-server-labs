/* ===============================================================================
   Author       : Senior SQL Server DBA / Software Architect
   Description  : Sunucudaki ana darboğazları (Disk, CPU, Lock, Memory) tespit etmek
                  için sistem Wait Stat'lerini analiz eder ve teşhis koyar.
   Target Engine: SQL Server 2012 ve üzeri
   =============================================================================== */

SET NOCOUNT ON;

WITH FilteredWaitStats AS (
    SELECT 
        wait_type,
        wait_time_ms / 1000.0 AS WaitTimeSec,
        (wait_time_ms - signal_wait_time_ms) / 1000.0 AS ResourceWaitSec,
        signal_wait_time_ms / 1000.0 AS SignalWaitSec,
        waiting_tasks_count AS WaitCount,
        100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS Percentage
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT IN (
        -- Sistemde doğal olarak bekleyen zararsız (Idle/Background) Wait Tipleri
        'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
        'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE',
        'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT',
        'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT',
        'CLR_AUTO_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
        'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'DIRTY_PAGE_POLL',
        'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'ONDEMAND_TASK_QUEUE'
    )
    AND wait_time_ms > 1000 -- Minimal beklemesi olanları ele
)
SELECT TOP 10
    wait_type AS WaitType,
    CAST(WaitTimeSec AS NUMERIC(12,2)) AS [Total Wait (Sec)],
    CAST(ResourceWaitSec AS NUMERIC(12,2)) AS [Resource Wait (Sec)],
    CAST(SignalWaitSec AS NUMERIC(12,2)) AS [CPU Signal Wait (Sec)],
    WaitCount,
    CAST(Percentage AS NUMERIC(5,2)) AS [Wait %],
    
    -- Akıllı Teşhis Mekanizması
    CASE 
        WHEN wait_type LIKE 'PAGEIOLATCH%' THEN '🚨 DISK I/O DARBOĞAZI: Veriler RAM de bulunamadı, diskten okuma bekleniyor. Memory artırın veya indeks eksiklerini çözün.'
        WHEN wait_type LIKE 'LCK_M%' THEN '🔒 BLOCKING / LOCKING: Sorgular birbirini kilitliyor! Transaction sürelerini kısaltın ve isolation level ları inceleyin.'
        WHEN wait_type IN ('CXPACKET', 'CXCONSUMER') THEN '⚡ PARALELİZM SORUNU: Sorgular paralel çalışırken thread beklemesi oluşuyor. MAXDOP veya Cost Threshold for Parallelism ayarını kontrol edin.'
        WHEN wait_type = 'SOS_SCHEDULER_YIELD' THEN '💻 CPU BASKISI: CPU thread lerinde yoğun kuyruk var. Yüksek CPU harcayan sorguları optimize edin.'
        WHEN wait_type LIKE 'ASYNC_NETWORK_IO' THEN '🌐 NETWORK / CLIENT YAVAŞLIĞI: SQL Server veriyi hazırladı ancak istemci (app) veriyi yavaş tüketiyor. SELECT * kullanımını bırakın.'
        WHEN wait_type LIKE 'WRITELOG' THEN '📝 TRANSACTION LOG DISK SPEED: Log diskinin I/O hızı yetersiz veya çok sık COMMIT atılıyor.'
        ELSE '🔎 İnceleme Gerektiriyor'
    END AS DiagnosisAndRecommendation

FROM FilteredWaitStats
ORDER BY Percentage DESC;