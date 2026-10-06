-- =========================================================================
-- 3. SCALAR FUNCTION: Doküman Bütünlük & SHA-256 Doğrulama (dms.fn_VerifyDocumentIntegrity)
-- =========================================================================
/* =========================================================================
   Fonksiyon Adı : dms.fn_VerifyDocumentIntegrity
   Açıklama      : Belirtilen versiyonun tablodaki FileHash değeri ile verilen
                   SHA-256 karmasını karşılaştırarak verinin bütünlüğünü doğrular.
   Yazar         : Database Architecture Team
   ========================================================================= */
CREATE OR ALTER FUNCTION dms.fn_VerifyDocumentIntegrity
(
    @VersionId BIGINT,
    @ProvidedHash VARCHAR(64)
)
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @IsValid BIT = 0;
    DECLARE @StoredHash VARCHAR(64);

    SELECT @StoredHash = FileHash
    FROM dms.DocumentVersions
    WHERE VersionId = @VersionId;

    IF @StoredHash IS NOT NULL AND LOWER(@StoredHash) = LOWER(@ProvidedHash)
    BEGIN
        SET @IsValid = 1;
    END

    RETURN @IsValid;
END;
GO

