/* ============================================================
   TRIGGER: dms.trg_PreventImmutableVersionUpdate
   Amaç: Doküman versiyonlarının (dms.DocumentVersions) immutable
         (değiştirilemez) yapısını korur. Var olan bir versiyonun
         güncellenmesini veya silinmesini engeller.
   ============================================================ */
CREATE TRIGGER dms.trg_PreventImmutableVersionUpdate
ON dms.DocumentVersions
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Eğer silme veya güncelleme işlemi gerçekleştiyse işlemi engelle ve Hata Fırlat
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        RAISERROR('DMS Mimari Kuralı: Doküman versiyonları (DocumentVersions) değiştirilemez (Immutable) ve silinemez.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO