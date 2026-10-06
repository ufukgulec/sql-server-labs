-- =========================================================================
-- 2. JOB: DMS_DB_AuditLogsRetentionCleanup
-- Amaç: audit.DocumentLogs tablosunda belirlenen günden (örn. 180 gün) 
-- eski olan log verilerini batch'ler halinde temizleyerek Transaction Log
-- sismesini ve kilitlenmeleri (lock-escalation) önler.
-- Çalışma Zamanı: Her gün 03:00
-- =========================================================================
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'DMS_DB_AuditLogsRetentionCleanup')
    EXEC dbo.sp_delete_job @job_name = N'DMS_DB_AuditLogsRetentionCleanup', @delete_unused_schedule=1;
GO

EXEC dbo.sp_add_job 
    @job_name = N'DMS_DB_AuditLogsRetentionCleanup',
    @enabled = 1,
    @description = N'Deletes audit log entries older than retention period in batches.';

EXEC dbo.sp_add_jobstep 
    @job_name = N'DMS_DB_AuditLogsRetentionCleanup',
    @step_name = N'Batch_Delete_Old_Logs',
    @subsystem = N'TSQL',
    @database_name = N'DMS_DB',
    @command = N'
SET NOCOUNT ON;
DECLARE @RetentionDays INT = 180;
DECLARE @CutoffDate DATETIME2(3) = DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());
DECLARE @DeletedRows INT = 1;
DECLARE @BatchSize INT = 5000;

WHILE @DeletedRows > 0
BEGIN
    DELETE TOP (@BatchSize) 
    FROM audit.DocumentLogs
    WHERE CreatedAt < @CutoffDate;

    SET @DeletedRows = @@ROWCOUNT;

    -- Transaction Log kilitlenmelerini engellemek için kısa duraklama
    WAITFOR DELAY ''00:00:01'';
END
';

EXEC dbo.sp_add_schedule 
    @schedule_name = N'Daily_03AM',
    @freq_type = 4, -- Daily
    @freq_interval = 1,
    @active_start_time = 030000;

EXEC dbo.sp_attach_schedule 
    @job_name = N'DMS_DB_AuditLogsRetentionCleanup',
    @schedule_name = N'Daily_03AM';

EXEC dbo.sp_add_jobserver 
    @job_name = N'DMS_DB_AuditLogsRetentionCleanup';
GO