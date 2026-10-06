SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- =========================================================================
-- 1. SCALAR FUNCTION: Hiyerarşik Klasör Yolu Oluşturucu (dms.fn_GetFolderPath)
-- =========================================================================
/* =========================================================================
   Fonksiyon Adı : dms.fn_GetFolderPath
   Açıklama      : Verilen FolderId değerine göre HIERARCHYID ağacını tarayarak
                   kökten klasöre kadar olan tam dizin yolunu (/Kök/Klasör) döner.
   Yazar         : Database Architecture Team
   ========================================================================= */
CREATE OR ALTER FUNCTION dms.fn_GetFolderPath
(
    @FolderId BIGINT
)
RETURNS NVARCHAR(MAX)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @FolderPath NVARCHAR(MAX);
    DECLARE @TargetNode HIERARCHYID;

    -- Hedef klasörün Node değerini al
    SELECT @TargetNode = Node 
    FROM dms.Folders 
    WHERE FolderId = @FolderId;

    IF @TargetNode IS NULL
        RETURN NULL;

    -- Hiyerarşik yolu string olarak oluştur
    SELECT @FolderPath = STRING_AGG(CAST(FolderName AS NVARCHAR(MAX)), '/') WITHIN GROUP (ORDER BY Level ASC)
    FROM dms.Folders
    WHERE @TargetNode.IsDescendantOf(Node) = 1;

    RETURN N'/' + ISNULL(@FolderPath, N'');
END;
GO