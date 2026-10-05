/* ============================================================
   DMS VERİTABANI - GELİŞMİŞ DUMMY (TEST) VERİ SETİ
   ============================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

USE DMS_DB;
GO

-- 1. TEST KULLANICILARI (sec.Users)
INSERT INTO sec.Users (Username, Email, PasswordHash, FirstName, LastName, IsActive)
VALUES 
('ahmet.yilmaz', 'ahmet.yilmaz@company.com', 'hash123', N'Ahmet', N'Yılmaz', 1),
('ayse.kaya', 'ayse.kaya@company.com', 'hash123', N'Ayşe', N'Kaya', 1),
('mehmet.demir', 'mehmet.demir@company.com', 'hash123', N'Mehmet', N'Demir', 1),
('canan.sahin', 'canan.sahin@company.com', 'hash123', N'Canan', N'Şahin', 1),
('zeynep.cetin', 'zeynep.cetin@company.com', 'hash123', N'Zeynep', N'Çetin', 0);
GO

-- 2. KULLANICI - GRUP EŞLEŞMELERİ (sec.UserGroups)
INSERT INTO sec.UserGroups (UserId, GroupId)
VALUES 
(3, 4), -- Ahmet -> GRP_IT
(3, 6), -- Ahmet -> GRP_ALL
(4, 2), -- Ayşe -> GRP_HR
(4, 6), -- Ayşe -> GRP_ALL
(5, 3), -- Mehmet -> GRP_FINANCE
(6, 5); -- Canan -> GRP_LEGAL
GO

-- 3. ALT KLASÖRLER (dms.Folders)
INSERT INTO dms.Folders (Node, FolderName, CreatedBy, IsActive)
VALUES 
(HIERARCHYID::Parse('/1/1/'), N'Özlük Dosyaları', 4, 1),
(HIERARCHYID::Parse('/1/2/'), N'Mülakat Notları', 4, 1),
(HIERARCHYID::Parse('/2/1/'), N'2026 Faturalar', 5, 1),
(HIERARCHYID::Parse('/2/2/'), N'Bütçe Raporları', 5, 1),
(HIERARCHYID::Parse('/3/1/'), N'Sistem Mimarisi', 3, 1),
(HIERARCHYID::Parse('/4/1/'), N'Müşteri Sözleşmeleri', 6, 1);
GO

-- 4. DOKÜMAN KAYITLARI (dms.Documents)
INSERT INTO dms.Documents (FolderId, DocumentNumber, Title, Description, OwnerId, IsLocked, LockedBy)
VALUES 
(10, 'DOC-2026-0001', N'Enterprise DMS Veritabanı Mimarisi', N'SQL Server 2022 tabanlı DMS veri modeli dokümanı', 3, 0, NULL),
(8,  'DOC-2026-0002', N'Sunucu Alım Faturası - Dell PowerEdge', N'Q1 Altyapı sunucu tedarik faturası', 5, 1, 5),
(11, 'DOC-2026-0003', N'Yazılım Lisans Sözleşmesi v2', N'Kurumsal SLA ve lisans kullanım şartları', 6, 0, NULL);
GO

-- 5. DOKÜMAN VERSİYONLARI (dms.DocumentVersions)
INSERT INTO dms.DocumentVersions (DocumentId, VersionMajor, VersionMinor, StorageProvider, FilePath, FileSizeKB, FileExtension, FileHash, ChangeLog, UploadedBy)
VALUES 
(1, 1, 0, 'AWS_S3', 's3://dms-bucket/2026/03/doc-1-v1.0.pdf', 2450, 'pdf', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', N'İlk taslak yüklendi', 3),
(1, 1, 1, 'AWS_S3', 's3://dms-bucket/2026/03/doc-1-v1.1.pdf', 2680, 'pdf', '2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae', N'Index stratejileri eklendi', 3),
(2, 1, 0, 'AZURE_BLOB', 'azure://dms-container/finance/2026/inv-002.pdf', 1120, 'pdf', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', N'Fatura taraması', 5),
(3, 1, 0, 'LOCAL_FILE', '/mnt/dms_storage/legal/contract_2026_03.docx', 512, 'docx', 'f4d5b2d184288b222a00cbe9121882d231920ae192019b819281928129182912', N'Hukuk onaylı nihai metin', 6);
GO

-- 6. GÜNCEL VERSİYON FK GÜNCELLEMESİ (CurrentVersionId)
UPDATE dms.Documents SET CurrentVersionId = 2 WHERE DocumentId = 1;
UPDATE dms.Documents SET CurrentVersionId = 3 WHERE DocumentId = 2;
UPDATE dms.Documents SET CurrentVersionId = 4 WHERE DocumentId = 3;
GO

-- 7. METADATA / DİNAMİK ETİKETLER (dms.DocumentMetadata)
INSERT INTO dms.DocumentMetadata (DocumentId, MetaKey, MetaValue)
VALUES 
(1, 'ProjectCode', 'PRJ-2026-DMS'),
(1, 'Confidentiality', 'Internal'),
(2, 'SupplierTaxNo', '9876543210'),
(2, 'InvoiceAmount', '45000.00'),
(2, 'Currency', 'USD'),
(3, 'ContractEndDate', '2027-12-31'),
(3, 'Signatory', 'Ahmet Yılmaz');
GO

-- 8. ERİŞİM KONTROL LİSTESİ / ACL (sec.AccessControlLists)
INSERT INTO sec.AccessControlLists (FolderId, DocumentId, PrincipalId, PrincipalType, CanRead, CanWrite, CanDelete, CanChangePermissions)
VALUES 
(4, NULL, 4, 'G', 1, 1, 1, 1),
(NULL, 3, 3, 'U', 1, 0, 0, 0);
GO

-- 9. AUDIT LOGLARI (audit.DocumentLogs)
INSERT INTO audit.DocumentLogs (DocumentId, VersionId, UserId, ActionType, IpAddress)
VALUES 
(1, 1, 3, 'CREATED', '192.168.1.50'),
(1, 2, 3, 'VERSION_ADDED', '192.168.1.50'),
(2, 3, 5, 'CREATED', '192.168.1.88'),
(2, 3, 5, 'LOCKED', '192.168.1.88'),
(3, 4, 6, 'CREATED', '192.168.1.102'),
(3, 4, 3, 'VIEWED', '192.168.1.50');
GO