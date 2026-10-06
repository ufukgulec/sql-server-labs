SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   PROCEDURE: dms.sp_CreateDocument
   Amaç: Yeni bir doküman ve bunun ilk versiyonunu (v1.0) atomik olarak
         oluşturur, CurrentVersionId alanını günceller ve audit log atar.
   ============================================================ */
CREATE OR ALTER PROCEDURE dms.sp_CreateDocument
    @FolderId        BIGINT,
    @DocumentNumber  VARCHAR(50),
    @Title           NVARCHAR(500),
    @Description     NVARCHAR(MAX) = NULL,
    @OwnerId         BIGINT,
    @StorageProvider VARCHAR(50),
    @FilePath        VARCHAR(1000),
    @FileSizeKB      BIGINT,
    @FileExtension   VARCHAR(10),
    @FileHash        VARCHAR(64),
    @IpAddress       VARCHAR(45) = NULL,
    @NewDocumentId   BIGINT OUTPUT,
    @NewVersionId    BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Klasör Kontrolü
        IF NOT EXISTS (SELECT 1 FROM dms.Folders WHERE FolderId = @FolderId AND IsActive = 1)
        BEGIN
            RAISERROR('Belirtilen klasör bulunamadı veya pasif durumda.', 16, 1);
        END

        -- 2. Doküman Numarası Mükerrerlik Kontrolü
        IF EXISTS (SELECT 1 FROM dms.Documents WHERE DocumentNumber = @DocumentNumber)
        BEGIN
            RAISERROR('Bu doküman numarası ("%s") zaten kullanılmaktadır.', 16, 1, @DocumentNumber);
        END

        -- 3. Ana Doküman Kaydı (CurrentVersionId geçici olarak NULL bırakılıyor)
        INSERT INTO dms.Documents
        (
            FolderId,
            DocumentNumber,
            Title,
            Description,
            CurrentVersionId,
            OwnerId,
            IsLocked,
            IsDeleted,
            CreatedAt,
            UpdatedAt
        )
        VALUES
        (
            @FolderId,
            @DocumentNumber,
            @Title,
            @Description,
            NULL,
            @OwnerId,
            0,
            0,
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        );

        SET @NewDocumentId = SCOPE_IDENTITY();

        -- 4. İlk Versiyon Kaydı (v1.0)
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
            @NewDocumentId,
            1,
            0,
            @StorageProvider,
            @FilePath,
            @FileSizeKB,
            @FileExtension,
            @FileHash,
            N'Initial upload (v1.0)',
            @OwnerId,
            SYSUTCDATETIME()
        );

        SET @NewVersionId = SCOPE_IDENTITY();

        -- 5. Dokümanın CurrentVersionId Değerini Güncelle
        UPDATE dms.Documents
        SET CurrentVersionId = @NewVersionId,
            UpdatedAt = SYSUTCDATETIME()
        WHERE DocumentId = @NewDocumentId;

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
            @NewDocumentId,
            @NewVersionId,
            @OwnerId,
            'CREATED',
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