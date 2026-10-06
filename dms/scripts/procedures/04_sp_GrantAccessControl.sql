/* ============================================================
   PROCEDURE: sec.sp_GrantAccessControl
   Amaç: Klasör veya Doküman için kullanıcı veya gruba yetki atar (UPSERT).
         Şemadaki CHK_ACL_Target (FolderId veya DocumentId'den biri NULL olmalı)
         kuralına uygun çalışır.
   ============================================================ */
CREATE OR ALTER PROCEDURE sec.sp_GrantAccessControl
    @FolderId             BIGINT = NULL,
    @DocumentId           BIGINT = NULL,
    @PrincipalId          BIGINT,
    @PrincipalType        CHAR(1), -- 'U': User, 'G': Group
    @CanRead              BIT = 0,
    @CanWrite             BIT = 0,
    @CanDelete            BIT = 0,
    @CanChangePermissions BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Hedef Kontrolü (Hedef yalnızca bir tablo olmalı)
        IF (@FolderId IS NULL AND @DocumentId IS NULL) OR (@FolderId IS NOT NULL AND @DocumentId IS NOT NULL)
        BEGIN
            RAISERROR('Aynı anda yalnızca bir hedef (ya FolderId ya da DocumentId) belirtilmelidir.', 16, 1);
        END

        -- 2. Principal Type Kontrolü
        IF @PrincipalType NOT IN ('U', 'G')
        BEGIN
            RAISERROR('PrincipalType değeri "U" (User) veya "G" (Group) olmalıdır.', 16, 1);
        END

        -- 3. Yetki Kaydı (UPSERT Mantığı - Existing Check)
        IF EXISTS (
            SELECT 1 
            FROM sec.AccessControlLists 
            WHERE ISNULL(FolderId, -1) = ISNULL(@FolderId, -1)
              AND ISNULL(DocumentId, -1) = ISNULL(@DocumentId, -1)
              AND PrincipalId = @PrincipalId
              AND PrincipalType = @PrincipalType
        )
        BEGIN
            -- Güncelle
            UPDATE sec.AccessControlLists
            SET CanRead = @CanRead,
                CanWrite = @CanWrite,
                CanDelete = @CanDelete,
                CanChangePermissions = @CanChangePermissions
            WHERE ISNULL(FolderId, -1) = ISNULL(@FolderId, -1)
              AND ISNULL(DocumentId, -1) = ISNULL(@DocumentId, -1)
              AND PrincipalId = @PrincipalId
              AND PrincipalType = @PrincipalType;
        END
        ELSE
        BEGIN
            -- Yeni Ekle
            INSERT INTO sec.AccessControlLists
            (
                FolderId,
                DocumentId,
                PrincipalId,
                PrincipalType,
                CanRead,
                CanWrite,
                CanDelete,
                CanChangePermissions
            )
            VALUES
            (
                @FolderId,
                @DocumentId,
                @PrincipalId,
                @PrincipalType,
                @CanRead,
                @CanWrite,
                @CanDelete,
                @CanChangePermissions
            );
        END

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