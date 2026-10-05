/* ============================================================
   PROCEDURE: itsm.sp_ResolveTicket
   Amaç: Bileti çözüldü olarak işaretler ve tarihçesini kaydeder.
   ============================================================ */

CREATE PROCEDURE itsm.sp_ResolveTicket
    @TicketId         BIGINT,
    @ResolutionNotes  NVARCHAR(MAX),
    @UpdatedByUserId  BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ResolvedStatusId INT;
        SELECT TOP 1 @ResolvedStatusId = TicketStatusId 
        FROM itsm.TicketStatuses 
        WHERE Code = N'RESOLVED' AND IsActive = 1;

        IF @ResolvedStatusId IS NULL
        BEGIN
            RAISERROR('Sistemde aktif "RESOLVED" (Çözüldü) statüsü bulunamadı.', 16, 1);
        END

        -- Biletin durumunu güncelle
        UPDATE itsm.Tickets
        SET TicketStatusId = @ResolvedStatusId,
            ResolvedAt = SYSUTCDATETIME(),
            UpdatedAt = SYSUTCDATETIME()
        WHERE TicketId = @TicketId;

        -- Çözüm notunu açıklama veya yorum olarak ekle
        INSERT INTO itsm.TicketComments
        (
            TicketId,
            UserId,
            Comment,
            IsInternal,
            CreatedAt
        )
        VALUES
        (
            @TicketId,
            @UpdatedByUserId,
            N'ÇÖZÜM NOTU: ' + @ResolutionNotes,
            0,
            SYSUTCDATETIME()
        );

        -- Audit Kaydı
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
        VALUES
        (
            @TicketId,
            @UpdatedByUserId,
            N'RESOLVE',
            N'TicketStatusId',
            CAST(@ResolvedStatusId AS NVARCHAR(50)),
            N'APPLICATION',
            SYSUTCDATETIME()
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO