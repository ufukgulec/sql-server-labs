
-- =========================================================================
-- 2. INLINE TABLE-VALUED FUNCTION: Kullanıcı Efektif Yetki Kontrolü (sec.fn_GetUserPermissions)
-- =========================================================================
/* =========================================================================
   Fonksiyon Adı : sec.fn_GetUserPermissions
   Açıklama      : Belirtilen kullanıcının hem bireysel hem de dahil olduğu tüm
                   gruplardan gelen yetkilerini tek bir tabloda birleştirerek
                   (UNION ALL + MAX Aggregation) efektif izinlerini döner.
                   Inline TVF olduğu için Query Optimizer tarafından Inlining uygulanır.
   Yazar         : Database Architecture Team
   ========================================================================= */
CREATE OR ALTER FUNCTION sec.fn_GetUserPermissions
(
    @UserId BIGINT
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH CombinedPermissions AS
    (
        -- 1. Bireysel Kullanıcı Yetkileri
        SELECT 
            acl.FolderId,
            acl.DocumentId,
            acl.CanRead,
            acl.CanWrite,
            acl.CanDelete,
            acl.CanChangePermissions
        FROM sec.AccessControlLists acl
        WHERE acl.PrincipalId = @UserId 
          AND acl.PrincipalType = 'U'

        UNION ALL

        -- 2. Üye Olunan Gruplardan Gelen Yetkiler
        SELECT 
            acl.FolderId,
            acl.DocumentId,
            acl.CanRead,
            acl.CanWrite,
            acl.CanDelete,
            acl.CanChangePermissions
        FROM sec.AccessControlLists acl
        INNER JOIN sec.UserGroups ug ON acl.PrincipalId = ug.GroupId
        WHERE ug.UserId = @UserId 
          AND acl.PrincipalType = 'G'
    )
    SELECT 
        FolderId,
        DocumentId,
        MAX(CAST(CanRead AS TINYINT)) AS CanRead,
        MAX(CAST(CanWrite AS TINYINT)) AS CanWrite,
        MAX(CAST(CanDelete AS TINYINT)) AS CanDelete,
        MAX(CAST(CanChangePermissions AS TINYINT)) AS CanChangePermissions
    FROM CombinedPermissions
    GROUP BY FolderId, DocumentId
);
GO
