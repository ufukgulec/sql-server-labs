SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   TRIGGER: dms.trg_DocumentAudit
   Amaç: Dokümanlar üzerindeki versiyon değişimi, kilitlenme, silinme
         veya klasör taşıma işlemlerini otomatik olarak Audit 
         log tablosuna (audit.DocumentLogs) kaydeder.
   ============================================================ */
CREATE TRIGGER dms.trg_DocumentAudit
ON dms.Documents
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Versiyon Değişikliği (CurrentVersionId değiştiyse)
    INSERT INTO audit.DocumentLogs
    (
        DocumentId,
        VersionId,
        UserId,
        ActionType,
        IpAddress,
        CreatedAt
    )
    SELECT 
        i.DocumentId,
        i.CurrentVersionId,
        i.OwnerId,
        'VERSION_CHANGED',
        NULL,
        SYSUTCDATETIME()
    FROM inserted i
    INNER JOIN deleted d ON i.DocumentId = d.DocumentId
    WHERE (i.CurrentVersionId <> d.CurrentVersionId) 
       OR (i.CurrentVersionId IS NOT NULL AND d.CurrentVersionId IS NULL);

    -- 2. Kilit Durumu Değişikliği (IsLocked / LockedBy)
    INSERT INTO audit.DocumentLogs
    (
        DocumentId,
        VersionId,
        UserId,
        ActionType,
        IpAddress,
        CreatedAt
    )
    SELECT 
        i.DocumentId,
        i.CurrentVersionId,
        ISNULL(i.LockedBy, i.OwnerId),
        CASE WHEN i.IsLocked = 1 THEN 'LOCKED' ELSE 'UNLOCKED' END,
        NULL,
        SYSUTCDATETIME()
    FROM inserted i
    INNER JOIN deleted d ON i.DocumentId = d.DocumentId
    WHERE i.IsLocked <> d.IsLocked;

    -- 3. Soft-Delete (Mantıksal Silme) Durumu Değişikliği
    INSERT INTO audit.DocumentLogs
    (
        DocumentId,
        VersionId,
        UserId,
        ActionType,
        IpAddress,
        CreatedAt
    )
    SELECT 
        i.DocumentId,
        i.CurrentVersionId,
        i.OwnerId,
        CASE WHEN i.IsDeleted = 1 THEN 'DELETED' ELSE 'RESTORED' END,
        NULL,
        SYSUTCDATETIME()
    FROM inserted i
    INNER JOIN deleted d ON i.DocumentId = d.DocumentId
    WHERE i.IsDeleted <> d.IsDeleted;

    -- 4. Klasör Taşıma (FolderId değiştiyse)
    INSERT INTO audit.DocumentLogs
    (
        DocumentId,
        VersionId,
        UserId,
        ActionType,
        IpAddress,
        CreatedAt
    )
    SELECT 
        i.DocumentId,
        i.CurrentVersionId,
        i.OwnerId,
        'MOVED',
        NULL,
        SYSUTCDATETIME()
    FROM inserted i
    INNER JOIN deleted d ON i.DocumentId = d.DocumentId
    WHERE i.FolderId <> d.FolderId;
END;
GO