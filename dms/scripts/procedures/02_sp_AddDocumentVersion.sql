/* ============================================================
   PROCEDURE: dms.sp_AddDocumentVersion
   Amaç: Dokümana yeni bir versiyon ekler, Major veya Minor versiyon
         numarasını günceller, kilitliyse kilidi kaldırır ve audit log atar.
   ============================================================ */
CREATE OR ALTER PROCEDURE dms.sp_AddDocumentVersion
    @DocumentId      BIGINT,
    @IsMajorVersion  BIT = 0,
    @StorageProvider VARCHAR(50),
    @FilePath        VARCHAR(1000),
    @FileSizeKB      BIGINT,
    @FileExtension   VARCHAR(10),
    @FileHash        VARCHAR(64),
    @ChangeLog       NVARCHAR(1000) = NULL,
    @UploadedBy      BIGINT,
    @IpAddress       VARCHAR(45) = NULL,
    @NewVersionId    BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Doküman Kontrolü ve Kilitleme (ROWLOCK, UPDLOCK ile tutarlılık)
        DECLARE @CurrentVersionId BIGINT;
        DECLARE @IsLocked BIT;
        DECLARE @LockedBy BIGINT;

        SELECT 
            @CurrentVersionId = CurrentVersionId,
            @IsLocked = IsLocked,
            @LockedBy = LockedBy
        FROM dms.Documents WITH (UPDLOCK, ROWLOCK)
        WHERE DocumentId = @DocumentId AND IsDeleted = 0;

        IF @CurrentVersionId IS NULL
        BEGIN
            RAISERROR('Doküman bulunamadı veya silinmiş durumda.', 16, 1);
        END

        -- 2. Kilit Kontrolü (Başka biri kilitlediyse engel ol)
        IF @IsLocked = 1 AND @LockedBy <> @UploadedBy
        BEGIN
            RAISERROR('Doküman başka bir kullanıcı tarafından kilitlendiği için yeni versiyon eklenemez.', 16, 1);
        END

        -- 3. Son Versiyon Numarasını Al ve Yeni Versiyon Numarasını Hesapla
        DECLARE @LastMajor INT;
        DECLARE @LastMinor INT;

        SELECT 
            @LastMajor = VersionMajor, 
            @LastMinor = VersionMinor
        FROM dms.DocumentVersions
        WHERE VersionId = @CurrentVersionId;

        DECLARE @NewMajor INT = @LastMajor;
        DECLARE @NewMinor INT = @LastMinor;

        IF @IsMajorVersion = 1
        BEGIN
            SET @NewMajor = @LastMajor + 1;
            SET @NewMinor = 0;
        END
        ELSE
        BEGIN
            SET @NewMinor = @LastMinor + 1;
        END

        -- 4. Yeni Versiyonu Kaydet
        INSERT INTO dms.DocumentVersions
        (
            DocumentId,
            VersionMajor,
            VersionMinor,
            StorageProvider,
            FilePath,
            FileSizeKB,
            FileExtension,
            FileHash,
            ChangeLog,
            UploadedBy,
            UploadedAt
        )
        VALUES
        (
            @DocumentId,
            @NewMajor,
            @NewMinor,
            @StorageProvider,
            @FilePath,
            @FileSizeKB,
            @FileExtension,
            @FileHash,
            @ChangeLog,
            @UploadedBy,
            SYSUTCDATETIME()
        );

        SET @NewVersionId = SCOPE_IDENTITY();

        -- 5. Dokümanı Güncelle (CurrentVersionId ve Kilit Kaldırma)
        UPDATE dms.Documents
        SET CurrentVersionId = @NewVersionId,
            IsLocked = 0,
            LockedBy = NULL,
            UpdatedAt = SYSUTCDATETIME()
        WHERE DocumentId = @DocumentId;

        -- 6. Audit Log Kaydı
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
            @NewVersionId,
            @UploadedBy,
            'VERSION_ADDED',
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