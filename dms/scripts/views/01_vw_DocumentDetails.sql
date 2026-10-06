SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dms.vw_DocumentDetails', 'V') IS NOT NULL
    DROP VIEW dms.vw_DocumentDetails;
GO

CREATE VIEW dms.vw_DocumentDetails
WITH SCHEMABINDING
AS
/* =========================================================================
   Nesne Adı : dms.vw_DocumentDetails
   Açıklama  : Silinmemiş aktif dokümanların detaylarını, bağlı oldukları klasör,
               sahibi, kilitleyen kullanıcı ve güncel versiyon bilgileriyle
               birlikte listeler.
   Yazar     : Database Architecture Team
   ========================================================================= */
SELECT 
    d.DocumentId,
    d.DocumentNumber,
    d.Title,
    d.Description,
    d.FolderId,
    f.FolderName,
    d.OwnerId,
    CONCAT(uOwner.FirstName, N' ', uOwner.LastName) AS OwnerFullName,
    uOwner.Email AS OwnerEmail,
    d.IsLocked,
    d.LockedBy,
    CONCAT(uLock.FirstName, N' ', uLock.LastName) AS LockedByFullName,
    d.CurrentVersionId,
    v.VersionMajor,
    v.VersionMinor,
    CONCAT(CAST(v.VersionMajor AS VARCHAR(10)), '.', CAST(v.VersionMinor AS VARCHAR(10))) AS VersionString,
    v.StorageProvider,
    v.FilePath,
    v.FileSizeKB,
    v.FileExtension,
    v.FileHash,
    v.UploadedAt AS LastVersionUploadedAt,
    v.UploadedBy AS LastVersionUploadedBy,
    CONCAT(uUp.FirstName, N' ', uUp.LastName) AS LastVersionUploadedByFullName,
    d.CreatedAt,
    d.UpdatedAt,
    d.RowVersion
FROM dms.Documents d
INNER JOIN dms.Folders f ON d.FolderId = f.FolderId
INNER JOIN sec.Users uOwner ON d.OwnerId = uOwner.UserId
LEFT JOIN sec.Users uLock ON d.LockedBy = uLock.UserId
LEFT JOIN dms.DocumentVersions v ON d.CurrentVersionId = v.VersionId
LEFT JOIN sec.Users uUp ON v.UploadedBy = uUp.UserId
WHERE d.IsDeleted = 0;
GO