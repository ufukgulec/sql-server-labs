-- =========================================================================
-- 3. JOB: DMS_DB_UnlockOrphanedDocumentLocks
-- Amaç: Sistemde belirli bir süreden uzun süre (örn. 12 saat) kilitli kalmış 
-- ve işlem görmemiş dokümanların kilitlerini otomatik kaldırır.
-- Çalışma Zamanı: Saatte Bir
-- =========================================================================
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'DMS_DB_UnlockOrphanedDocumentLocks')
    EXEC dbo.sp_delete_job @job_name = N'DMS_DB_UnlockOrphanedDocumentLocks', @delete_unused_schedule=1;
GO

EXEC dbo.sp_add_job 
    @job_name = N'DMS_DB_UnlockOrphanedDocumentLocks',
    @enabled = 1,
    @description = N'Releases locks on documents that have been locked longer than timeout thresholds.';

EXEC dbo.sp_add_jobstep 
    @job_name = N'DMS_DB_UnlockOrphanedDocumentLocks',
    @step_name = N'Release_Expired_Locks',
    @subsystem = N'TSQL',
    @database_name = N'DMS_DB',
    @command = N'
SET NOCOUNT ON;
DECLARE @LockTimeoutHours INT = 12;

UPDATE dms.Documents
SET IsLocked = 0,
    LockedBy = NULL,
    UpdatedAt = SYSUTCDATETIME()
WHERE IsLocked = 1
  AND UpdatedAt < DATEADD(HOUR, -@LockTimeoutHours, SYSUTCDATETIME());
';

EXEC dbo.sp_add_schedule 
    @schedule_name = N'Hourly_Schedule',
    @freq_type = 4, -- Daily
    @freq_interval = 1,
    @freq_subday_type = 8, -- Hours
    @freq_subday_interval = 1,
    @active_start_time = 000000;

EXEC dbo.sp_attach_schedule 
    @job_name = N'DMS_DB_UnlockOrphanedDocumentLocks',
    @schedule_name = N'Hourly_Schedule';

EXEC dbo.sp_add_jobserver 
    @job_name = N'DMS_DB_UnlockOrphanedDocumentLocks';
GO