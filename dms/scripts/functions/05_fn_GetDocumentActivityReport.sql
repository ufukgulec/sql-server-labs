-- =========================================================================
-- 5. MULTI-STATEMENT TABLE-VALUED FUNCTION: Doküman Detaylı Audit Özeti (audit.fn_GetDocumentActivityReport)
-- =========================================================================
/* =========================================================================
   Fonksiyon Adı : audit.fn_GetDocumentActivityReport
   Açıklama      : Belirli bir tarih aralığında doküman bazında gerçekleşen 
                   işlem sayılarını (İndirme, Görüntüleme, Kilitlenme vb.) 
                   özet tablo olarak döndürür.
   Yazar         : Database Architecture Team
   ========================================================================= */
CREATE OR ALTER FUNCTION audit.fn_GetDocumentActivityReport
(
    @StartDate DATETIME2(3),
    @EndDate DATETIME2(3)
)
RETURNS @ReportTable TABLE
(
    DocumentId BIGINT PRIMARY KEY,
    TotalActions BIGINT,
    ViewCount INT,
    DownloadCount INT,
    VersionAddedCount INT,
    LockedCount INT,
    LastActionAt DATETIME2(3)
)
AS
BEGIN
    INSERT INTO @ReportTable
    (
        DocumentId,
        TotalActions,
        ViewCount,
        DownloadCount,
        VersionAddedCount,
        LockedCount,
        LastActionAt
    )
    SELECT 
        l.DocumentId,
        COUNT(l.LogId) AS TotalActions,
        SUM(CASE WHEN l.ActionType = 'VIEWED' THEN 1 ELSE 0 END) AS ViewCount,
        SUM(CASE WHEN l.ActionType = 'DOWNLOADED' THEN 1 ELSE 0 END) AS DownloadCount,
        SUM(CASE WHEN l.ActionType = 'VERSION_ADDED' THEN 1 ELSE 0 END) AS VersionAddedCount,
        SUM(CASE WHEN l.ActionType = 'LOCKED' THEN 1 ELSE 0 END) AS LockedCount,
        MAX(l.CreatedAt) AS LastActionAt
    FROM audit.DocumentLogs l
    WHERE l.CreatedAt >= @StartDate 
      AND l.CreatedAt <= @EndDate
    GROUP BY l.DocumentId;

    RETURN;
END;
GO