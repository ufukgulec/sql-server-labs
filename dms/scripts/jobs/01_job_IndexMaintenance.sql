USE msdb;
GO

-- =========================================================================
-- 1. JOB: DMS_DB_IndexAndStatsMaintenance
-- Amaç: İndeks parçalanmasını (fragmentation) analiz eder, duruma göre
-- REORGANIZE veya REBUILD çalıştırır ve istatistikleri günceller.
-- Çalışma Zamanı: Her Pazar 02:00
-- =========================================================================
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'DMS_DB_IndexAndStatsMaintenance')
    EXEC dbo.sp_delete_job @job_name = N'DMS_DB_IndexAndStatsMaintenance', @delete_unused_schedule=1;
GO

EXEC dbo.sp_add_job 
    @job_name = N'DMS_DB_IndexAndStatsMaintenance',
    @enabled = 1,
    @description = N'Index defragmentation and statistics update for DMS_DB.';

EXEC dbo.sp_add_jobstep 
    @job_name = N'DMS_DB_IndexAndStatsMaintenance',
    @step_name = N'Rebuild_Reorganize_Indexes',
    @subsystem = N'TSQL',
    @database_name = N'DMS_DB',
    @command = N'
SET NOCOUNT ON;
DECLARE @TableName NVARCHAR(255);
DECLARE @IndexName NVARCHAR(255);
DECLARE @AvgFrag FLOAT;
DECLARE @SQL NVARCHAR(MAX);

DECLARE IndexCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(N''DMS_DB''), NULL, NULL, NULL, ''LIMITED'') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10.0 
  AND i.name IS NOT NULL;

OPEN IndexCursor;
FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName, @AvgFrag;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @AvgFrag > 30.0
    BEGIN
        SET @SQL = N''ALTER INDEX ['' + @IndexName + N''] ON ['' + @TableName + N''] REBUILD WITH (ONLINE = ON);'';
    END
    ELSE IF @AvgFrag BETWEEN 10.0 AND 30.0
    BEGIN
        SET @SQL = N''ALTER INDEX ['' + @IndexName + N''] ON ['' + @TableName + N''] REORGANIZE;'';
    END

    BEGIN TRY
        EXEC sp_executesql @SQL;
    END TRY
    BEGIN CATCH
        -- Online rebuild desteklenmiyorsa offline dene
        IF @AvgFrag > 30.0
        BEGIN
            SET @SQL = N''ALTER INDEX ['' + @IndexName + N''] ON ['' + @TableName + N''] REBUILD;'';
            EXEC sp_executesql @SQL;
        END
    END CATCH

    FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName, @AvgFrag;
END

CLOSE IndexCursor;
DEALLOCATE IndexCursor;

EXEC sp_updatestats;
';

EXEC dbo.sp_add_schedule 
    @schedule_name = N'Weekly_Sunday_02AM',
    @freq_type = 8, -- Weekly
    @freq_interval = 1, -- Sunday
    @freq_recurrence_factor = 1,
    @active_start_time = 020000;

EXEC dbo.sp_attach_schedule 
    @job_name = N'DMS_DB_IndexAndStatsMaintenance',
    @schedule_name = N'Weekly_Sunday_02AM';

EXEC dbo.sp_add_jobserver 
    @job_name = N'DMS_DB_IndexAndStatsMaintenance';
GO