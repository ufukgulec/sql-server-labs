/* ============================================================
   TRIGGER: dms.trg_SetDocumentUpdatedAt
   Amaç: Doküman kaydı güncellendiğinde UpdatedAt zaman damgasını
         otomatik olarak SYSUTCDATETIME() yapar.
   ============================================================ */
CREATE TRIGGER dms.trg_SetDocumentUpdatedAt
ON dms.Documents
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Sonsuz döngüyü (recursion) önlemek için UpdatedAt alanının değişip değişmediğini kontrol et
    IF UPDATE(UpdatedAt) AND NOT EXISTS (
        SELECT 1 
        FROM inserted i 
        INNER JOIN deleted d ON i.DocumentId = d.DocumentId 
        WHERE i.UpdatedAt = d.UpdatedAt
    )
    BEGIN
        RETURN;
    END

    UPDATE d
    SET UpdatedAt = SYSUTCDATETIME()
    FROM dms.Documents d
    INNER JOIN inserted i ON d.DocumentId = i.DocumentId;
END;
GO