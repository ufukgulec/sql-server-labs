IF OBJECT_ID('sec.vw_UserEffectivePermissions', 'V') IS NOT NULL
    DROP VIEW sec.vw_UserEffectivePermissions;
GO

CREATE VIEW sec.vw_UserEffectivePermissions
AS
/* =========================================================================
   Nesne Adı : sec.vw_UserEffectivePermissions
   Açıklama  : Kullanıcıların hem doğrudan tanımlı hem de üye oldukları
               gruplar üzerinden kazandıkları izinleri (ACL) konsolide ederek
               klasör ve doküman bazlı efektif yetki matrisini çıkarır.
   Yazar     : Database Architecture Team
   ========================================================================= */
WITH RawPermissions AS (
    -- 1. Bireysel Kullanıcı Yetkileri
    SELECT 
        acl.PrincipalId AS UserId,
        acl.FolderId,
        acl.DocumentId,
        acl.CanRead,
        acl.CanWrite,
        acl.CanDelete,
        acl.CanChangePermissions
    FROM sec.AccessControlLists acl
    WHERE acl.PrincipalType = 'U'

    UNION ALL

    -- 2. Grup Üyeliklerinden Gelen Yetkiler
    SELECT 
        ug.UserId,
        acl.FolderId,
        acl.DocumentId,
        acl.CanRead,
        acl.CanWrite,
        acl.CanDelete,
        acl.CanChangePermissions
    FROM sec.AccessControlLists acl
    INNER JOIN sec.UserGroups ug ON acl.PrincipalId = ug.GroupId
    WHERE acl.PrincipalType = 'G'
)
SELECT 
    p.UserId,
    u.Username,
    p.FolderId,
    p.DocumentId,
    MAX(CAST(p.CanRead AS TINYINT)) AS CanRead,
    MAX(CAST(p.CanWrite AS TINYINT)) AS CanWrite,
    MAX(CAST(p.CanDelete AS TINYINT)) AS CanDelete,
    MAX(CAST(p.CanChangePermissions AS TINYINT)) AS CanChangePermissions
FROM RawPermissions p
INNER JOIN sec.Users u ON p.UserId = u.UserId
WHERE u.IsActive = 1
GROUP BY p.UserId, u.Username, p.FolderId, p.DocumentId;
GO