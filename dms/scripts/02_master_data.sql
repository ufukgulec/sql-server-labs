/* ============================================================
   DMS VERİTABANI - MASTER (ANA) VERİLER
   ============================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

USE DMS_DB;
GO

-- 1. SİSTEM VE YÖNETİCİ KULLANICILARI (sec.Users)
INSERT INTO sec.Users (Username, Email, PasswordHash, FirstName, LastName, IsActive)
VALUES 
('system.admin', 'admin@company.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'System', N'Administrator', 1),
('sys.service', 'service@company.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'System', N'ServiceAccount', 1);
GO

-- 2. KURUMSAL TEMEL GRUPLAR (sec.Groups)
INSERT INTO sec.Groups (GroupCode, GroupName, Description, IsActive)
VALUES 
('GRP_ADMIN', N'Sistem Yöneticileri', N'Tüm sistem yetkilerine sahip üst grup', 1),
('GRP_HR', N'İnsan Kaynakları', N'İK departmanı erişim grubu', 1),
('GRP_FINANCE', N'Finans ve Muhasebe', N'Mali evraklar ve fatura yönetimi', 1),
('GRP_IT', N'Bilgi Teknolojileri', N'Yazılım ve altyapı dokümantasyonu', 1),
('GRP_LEGAL', N'Hukuk', N'Sözleşmeler ve yasal evraklar', 1),
('GRP_ALL', N'Tüm Personel', N'Genel doküman erişim grubu', 1);
GO

-- 3. SİSTEM ADMIN USER - GROUP ATAMASI
INSERT INTO sec.UserGroups (UserId, GroupId)
VALUES (1, 1); -- system.admin -> GRP_ADMIN
GO

-- 4. KÖK VE ANA DEPARTMAN KLASÖRLERİ (dms.Folders)
INSERT INTO dms.Folders (Node, FolderName, CreatedBy, IsActive)
VALUES 
(HIERARCHYID::Parse('/'), N'Root', 1, 1),
(HIERARCHYID::Parse('/1/'), N'İnsan Kaynakları', 1, 1),
(HIERARCHYID::Parse('/2/'), N'Finans & Muhasebe', 1, 1),
(HIERARCHYID::Parse('/3/'), N'Bilgi Teknolojileri', 1, 1),
(HIERARCHYID::Parse('/4/'), N'Hukuk & Sözleşmeler', 1, 1);
GO