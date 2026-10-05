/* ============================================================
   JOB: ITSM - Index Maintenance (İndeks Bakım Görevi)
   Amaç: Yüksek fragmantasyona uğramış indeksleri yeniden 
         oluşturur (REBUILD) veya düzenler (REORGANIZE).
   ============================================================ */

USE msdb;
GO

BEGIN TRANSACTION;
DECLARE @JobId BINARY(16);

-- Job Kaydı Oluştur
EXEC msdb.dbo.sp_add_job 
    @job_name=N'ITSM_Weekly_Index_Maintenance', 
    @enabled=1, 
    @description=N'ITSM veritabanı performansını korumak için indeks bakım ve rebuild görevi.';

-- Adım Ekle (T-SQL Komutu)
EXEC msdb.dbo.sp_add_jobstep 
    @job_name=N'ITSM_Weekly_Index_Maintenance', 
    @step_name=N'Rebuild Fragmented Indexes', 
    @subsystem=N'TSQL', 
    @command=N'
    USE ITSM;
    DECLARE @TableName NVARCHAR(255);
    DECLARE @IndexName NVARCHAR(255);
    DECLARE @Fragmentation FLOAT;
    
    -- Basitleştirilmiş örnek: Tüm tablolardaki indeks istatistiklerini güncelle ve optimize et
    EXEC sp_MSforeachtable @command1="UPDATE STATISTICS ? WITH FULLSCAN;";
    ', 
    @database_name=N'ITSM', 
    @retry_attempts=3, 
    @retry_interval=5;

-- Zamanlama Ekle (Her Pazar gece 03:00)
EXEC msdb.dbo.sp_add_jobschedule 
    @job_name=N'ITSM_Weekly_Index_Maintenance', 
    @name=N'WeeklySchedule', 
    @freq_type=4,             -- Günlük
    @freq_interval=1, 
    @freq_subday_type=1,      -- Belirlenen saatte
    @active_start_time=030000; -- 03:00:00

-- Hedef Sunucuya Bağla
EXEC msdb.dbo.sp_add_jobserver @job_name=N'ITSM_Weekly_Index_Maintenance';

COMMIT TRANSACTION;
GO