/* ============================================================
   JOB: ITSM - SLA Breach Scanner (SLA İhlal Denetim Görevi)
   Amaç: Süresi dolan ve açık kalan biletleri tespit eder.
   ============================================================ */

USE msdb;
GO

BEGIN TRANSACTION;

EXEC msdb.dbo.sp_add_job 
    @job_name=N'ITSM_Hourly_SLA_Breach_Check', 
    @enabled=1, 
    @description=N'Her saat başı çalışarak süresi dolan biletleri raporlar.';

EXEC msdb.dbo.sp_add_jobstep 
    @job_name=N'ITSM_Hourly_SLA_Breach_Check', 
    @step_name=N'Log Breached Tickets', 
    @subsystem=N'TSQL', 
    @command=N'
    USE ITSM;
    
    -- Süresi geçmiş ve henüz kapatılmamış biletleri tarihçeye SLA_BREACH olarak ekle
    INSERT INTO itsm.TicketHistory
    (
        TicketId,
        UserId,
        ActionType,
        FieldName,
        NewValue,
        Source,
        CreatedAt
    )
    SELECT 
        t.TicketId,
        ISNULL(t.AssigneeId, 0),
        N''SLA_BREACH'',
        N''DueAt'',
        CAST(t.DueAt AS NVARCHAR(50)),
        N''JOB'',
        SYSUTCDATETIME()
    FROM itsm.Tickets t
    INNER JOIN itsm.TicketStatuses ts ON t.TicketStatusId = ts.TicketStatusId
    WHERE ts.IsClosed = 0
      AND t.DueAt < SYSUTCDATETIME()
      AND NOT EXISTS 
      (
          -- Daha önce bu uyarı atıldıysa tekrar atma
          SELECT 1 FROM itsm.TicketHistory th 
          WHERE th.TicketId = t.TicketId AND th.ActionType = N''SLA_BREACH''
      );
    ', 
    @database_name=N'ITSM', 
    @retry_attempts=1;

-- Her 1 saatte bir çalıştır
EXEC msdb.dbo.sp_add_jobschedule 
    @job_name=N'ITSM_Hourly_SLA_Breach_Check', 
    @name=N'HourlySchedule', 
    @freq_type=4, 
    @freq_interval=1,
    @freq_subday_type=8,      -- Saatlik
    @freq_subday_interval=1;  -- Her 1 saat

EXEC msdb.dbo.sp_add_jobserver @job_name=N'ITSM_Hourly_SLA_Breach_Check';

COMMIT TRANSACTION;
GO