/* ============================================================
   PROCEDURE: dms.sp_ToggleDocumentLock
   Amaç: Dokümanı kilitler (Check-Out) veya kilidini kaldırır (Check-In).
         Eşzamanlı düzenleme çatışmalarını engellemek için kullanılır.
   ============================================================ */
CREATE OR ALTER PROCEDURE dms.sp_ToggleDocumentLock
    @DocumentId BIGINT,
    @UserId     BIGINT,
    @Lock       BIT, -- 1: Kilitle, 0: Kilidi Aç
    @IpAddress  VARCHAR(45) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentIsLocked BIT;
        DECLARE @CurrentLockedBy BIGINT;

        SELECT 
            @CurrentIsLocked = IsLocked,
            @CurrentLockedBy = LockedBy
        FROM dms.Documents WITH (UPDLOCK, ROWLOCK)
        WHERE DocumentId = @DocumentId AND IsDeleted = 0;

        IF @CurrentIsLocked IS NULL
        BEGIN
            RAISERROR('Doküman bulunamadı veya silinmiş.', 16, 1);
        END

        IF @Lock = 1
        BEGIN
            -- Zaten kilitliyse ve kilitleyen kişi farklıysa
            IF @CurrentIsLocked = 1 AND @CurrentLockedBy <> @UserId
            BEGIN
                RAISERROR('Doküman zaten başka bir kullanıcı tarafından kilitlenmiş.', 16, 1);
            END

            UPDATE dms.Documents
            SET IsLocked = 1,
                LockedBy = @UserId,
                UpdatedAt = SYSUTCDATETIME()
            WHERE DocumentId = @DocumentId;
        END
        ELSE
        BEGIN
            -- Kilit açılmak isteniyor ama kilitli değilse
            IF @CurrentIsLocked = 0
            BEGIN
                RAISERROR('Doküman zaten kilitli değil.', 16, 1);
            END

            -- Kilidi açmak isteyen kişi kilitleyen kişi veya Admin/Owner değilse (Opsiyonel güvenlik)
            IF @CurrentLockedBy <> @UserId
            BEGIN
                RAISERROR('Bu dokümanın kilidini yalnızca kilitleyen kullanıcı kaldırabilir.', 16, 1);
            END

            UPDATE dms.Documents
            SET IsLocked = 0,
                LockedBy = NULL,
                UpdatedAt = SYSUTCDATETIME()
            WHERE DocumentId = @DocumentId;
        END

        -- Audit Log Kaydı
        INSERT INTO audit.DocumentLogs
        (
            DocumentId,
            VersionId,
            UserId,
            ActionType,
            IpAddress,
            CreatedAt
        )
        VALUES
        (
            @DocumentId,
            NULL,
            @UserId,
            CASE WHEN @Lock = 1 THEN 'LOCKED' ELSE 'UNLOCKED' END,
            @IpAddress,
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