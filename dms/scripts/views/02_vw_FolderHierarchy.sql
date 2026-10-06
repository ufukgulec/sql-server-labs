IF OBJECT_ID('dms.vw_FolderHierarchy', 'V') IS NOT NULL
    DROP VIEW dms.vw_FolderHierarchy;
GO

CREATE VIEW dms.vw_FolderHierarchy
WITH SCHEMABINDING
AS
/* =========================================================================
   Nesne Adı : dms.vw_FolderHierarchy
   Açıklama  : Klasörlerin HIERARCHYID ağaç yapısını analiz eder, her bir
               klasörün kökten itibaren olan tam dizin yolunu (Breadcrumb)
               ve ebeveyn bilgilerini türetir.
   Yazar     : Database Architecture Team
   ========================================================================= */
SELECT 
    f.FolderId,
    f.Node,
    f.Node.ToString() AS NodeString,
    f.Level,
    f.FolderName,
    f.CreatedBy,
    CONCAT(u.FirstName, N' ', u.LastName) AS CreatedByFullName,
    f.CreatedAt,
    f.IsActive,
    -- Üst Klasör (Parent) Node Bilgisi
    f.Node.GetAncestor(1) AS ParentNode,
    -- Hiyerarşik Breadcrumb Dizin Yolu (/Kök/Klasör1/Klasör2)
    (
        SELECT N'/' + fParent.FolderName
        FROM dms.Folders fParent
        WHERE f.Node.IsDescendantOf(fParent.Node) = 1
        ORDER BY fParent.Level
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)') AS FolderPath
FROM dms.Folders f
INNER JOIN sec.Users u ON f.CreatedBy = u.UserId;
GO