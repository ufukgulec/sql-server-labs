/* ============================================================
   ITSM VERİTABANI - KAPSAMLI DUMMY (TEST) DATA SCRIPT
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

USE ITSM;
GO

PRINT 'Kapsamlı dummy veriler yükleniyor...';
GO

-- 1. DEPARTMENTS
INSERT INTO itsm.Departments (Code, Name, IsActive) VALUES
(N'IT', N'Bilgi Teknolojileri', 1),
(N'HR', N'İnsan Kaynakları', 1),
(N'FIN', N'Finans ve Muhasebe', 1),
(N'OPS', N'Operasyon ve Destek', 1);
GO

-- 2. USERS
INSERT INTO itsm.Users (Username, FirstName, LastName, Email, DepartmentId, IsActive) VALUES
(N'admin', N'System', N'Admin', N'admin@itsm.local', 1, 1),
(N'ufuk.gulec', N'Orhan Ufuk', N'Güleç', N'ufuk.gulec@itsm.local', 1, 1),
(N'ahmet.yilmaz', N'Ahmet', N'Yılmaz', N'ahmet.yilmaz@itsm.local', 1, 1),
(N'ayse.demir', N'Ayşe', N'Demir', N'ayse.demir@itsm.local', 2, 1),
(N'mehmet.kaya', N'Mehmet', N'Kaya', N'mehmet.kaya@itsm.local', 3, 1),
(N'zeynep.celik', N'Zeynep', N'Çelik', N'zeynep.celik@itsm.local', 4, 1);
GO

-- 3. ROLES
INSERT INTO itsm.Roles (Code, Name, IsActive) VALUES
(N'SUPER_ADMIN', N'Süper Yönetici', 1),
(N'IT_SUPPORT', N'IT Destek Personeli', 1),
(N'DEPARTMENT_MANAGER', N'Departman Yöneticisi', 1),
(N'END_USER', N'Son Kullanıcı', 1);
GO

-- 4. USER ROLES
INSERT INTO itsm.UserRoles (UserId, RoleId) VALUES
(1, 1),
(2, 2),
(3, 2),
(4, 3),
(5, 4),
(6, 4);
GO

-- 5. TICKET TYPES
INSERT INTO itsm.TicketTypes (Code, Name, IsActive) VALUES
(N'INCIDENT', N'Arıza / Olay (Incident)', 1),
(N'SERVICE_REQUEST', N'Hizmet Talebi (Request)', 1),
(N'PROBLEM', N'Problem Yönetimi', 1),
(N'CHANGE', N'Değişiklik Talebi (Change)', 1);
GO

-- 6. TICKET STATUSES
INSERT INTO itsm.TicketStatuses (Code, Name, IsClosed, SortOrder, IsActive) VALUES
(N'NEW', N'Yeni', 0, 10, 1),
(N'IN_PROGRESS', N'Üzerinde Çalışılıyor', 0, 20, 1),
(N'PENDING', N'Beklemede', 0, 30, 1),
(N'RESOLVED', N'Çözüldü', 1, 40, 1),
(N'CLOSED', N'Kapatıldı', 1, 50, 1),
(N'CANCELLED', N'İptal Edildi', 1, 60, 1);
GO

-- 7. TICKET PRIORITIES
INSERT INTO itsm.TicketPriorities (Code, Name, PriorityLevel, IsActive) VALUES
(N'LOW', N'Düşük', 2, 1),
(N'MEDIUM', N'Normal', 5, 1),
(N'HIGH', N'Yüksek', 8, 1),
(N'CRITICAL', N'Kritik / Acil', 10, 1);
GO

-- 8. CATEGORIES
INSERT INTO itsm.Categories (ParentCategoryId, Code, Name, IsActive) VALUES
(NULL, N'HW', N'Donanım', 1),
(NULL, N'SW', N'Yazılım', 1),
(NULL, N'NET', N'Ağ ve İnternet', 1),
(NULL, N'ACC', N'Yetki ve Hesaplar', 1);

INSERT INTO itsm.Categories (ParentCategoryId, Code, Name, IsActive) VALUES
(1, N'HW_PC', N'Masaüstü / Laptop Arızası', 1),
(1, N'HW_PRN', N'Yazıcı ve Tarayıcı', 1),
(2, N'SW_OFFICE', N'Office 365 / Lisans', 1),
(3, N'NET_VPN', N'VPN Bağlantı Sorunları', 1);
GO

-- 9. SERVICES
INSERT INTO itsm.Services (Code, Name, OwnerUserId, IsActive) VALUES
(N'SRV_ERP', N'Kurumsal ERP Sistemi', 2, 1),
(N'SRV_MAIL', N'E-Posta Hizmetleri', 3, 1),
(N'SRV_PRINT', N'Ortak Yazıcı Havuzu', 3, 1);
GO

-- 10. SLA POLICIES
INSERT INTO itsm.SlaPolicies (Code, Name, ResponseTimeMin, ResolutionTimeMin, IsActive) VALUES
(N'SLA_CRITICAL', N'Kritik Seviye SLA (15dk / 2 Saat)', 15, 120, 1),
(N'SLA_STANDARD', N'Standart SLA (60dk / 24 Saat)', 60, 1440, 1),
(N'SLA_LOW', N'Düşük Öncelik SLA (240dk / 72 Saat)', 240, 4320, 1);
GO

-- 11. ASSIGNMENT GROUPS
INSERT INTO itsm.AssignmentGroups (Code, Name, ManagerUserId, IsActive) VALUES
(N'GRP_HELPCORE', N'1. Seviye Destek Masası', 2, 1),
(N'GRP_SYSADMIN', N'Sistem ve Ağ Yönetimi', 3, 1),
(N'GRP_DEV', N'Yazılım Geliştirme Ekibi', 2, 1);
GO

-- 12. ASSIGNMENT GROUP MEMBERS
INSERT INTO itsm.AssignmentGroupMembers (AssignmentGroupId, UserId) VALUES
(1, 2),
(1, 3),
(2, 3),
(3, 2);
GO

-- 13. TICKETS
INSERT INTO itsm.Tickets 
(
    Subject, Description, TicketTypeId, TicketStatusId, TicketPriorityId, 
    CategoryId, ServiceId, DepartmentId, RequesterId, AssignmentGroupId, AssigneeId, SlaPolicyId, DueAt
) 
VALUES
(
    N'VPN bağlantısı kopuyor ve bağlanamıyorum', 
    N'Şirket dışından VPN ile bağlanmaya çalışırken kimlik doğrulama hatası alıyorum.',
    1, 2, 3, 8, 2, 2, 4, 1, 2, 1, DATEADD(hour, 4, SYSUTCDATETIME())
),
(
    N'Yeni bilgisayar kurulum talebi', 
    N'Departmanımıza yeni katılan personel için dizüstü bilgisayar talep ediyorum.',
    2, 1, 2, 5, 1, 3, 5, 3, NULL, 2, DATEADD(day, 2, SYSUTCDATETIME())
),
(
    N'ERP Rapor ekranı yavaş çalışıyor', 
    N'Ay sonu mutabakat raporunu alırken sistem kilitleniyor.',
    1, 2, 4, 2, 1, 3, 6, 3, 3, 1, DATEADD(hour, 2, SYSUTCDATETIME())
);
GO

-- 14. TICKET STATUS TRANSITIONS
INSERT INTO itsm.TicketStatusTransitions (FromStatusId, ToStatusId, IsActive) VALUES
(1, 2),
(2, 3),
(3, 2),
(2, 4),
(4, 5),
(1, 6);
GO

-- 15. TICKET COMMENTS
INSERT INTO itsm.TicketComments (TicketId, UserId, Comment, IsInternal) VALUES
(1, 2, N'Kullanıcı şifresi expire olmuş olabilir, kontrol ediliyor.', 1),
(1, 4, N'Şifremi dün yenilemiştim ama hala bağlanamıyorum.', 0),
(3, 3, N'İlgili SQL sorgusu optimize ediliyor.', 1);
GO

-- 16. TAGS
INSERT INTO itsm.Tags (Name, IsActive) VALUES
(N'Donanım', 1),
(N'Acil', 1),
(N'ERP', 1),
(N'VPN', 1),
(N'Lisans', 1);
GO

-- 17. TICKET TAGS
INSERT INTO itsm.TicketTags (TicketId, TagId) VALUES
(1, 4),
(1, 2),
(2, 1),
(3, 3),
(3, 2);
GO

-- 18. TICKET WATCHERS
INSERT INTO itsm.TicketWatchers (TicketId, UserId) VALUES
(1, 2),
(3, 2),
(3, 4);
GO

-- 19. TICKET WORKLOGS
INSERT INTO itsm.TicketWorkLogs (TicketId, UserId, StartedAt, EndedAt, DurationMinutes, Description, IsBillable) VALUES
(1, 2, DATEADD(minute, -90, SYSUTCDATETIME()), DATEADD(minute, -30, SYSUTCDATETIME()), 60, N'VPN Log analizi yapıldı.', 1),
(3, 3, DATEADD(minute, -180, SYSUTCDATETIME()), DATEADD(minute, -120, SYSUTCDATETIME()), 60, N'Index optimizasyonu yapıldı.', 1);
GO

-- ============================================================
-- YENİ EKLENEN KAPSAMLI TABLOLAR (AUDIT, ATTACHMENTS, LINKS VB.)
-- ============================================================

-- 20. TICKET HISTORY / AUDIT
INSERT INTO itsm.TicketHistory (TicketId, UserId, ActionType, FieldName, OldValue, NewValue, OldDisplayValue, NewDisplayValue, Source, CorrelationId) VALUES
(1, 4, N'INSERT', NULL, NULL, NULL, NULL, NULL, N'APPLICATION', NEWID()),
(1, 2, N'UPDATE', N'TicketStatusId', N'1', N'2', N'Yeni', N'Üzerinde Çalışılıyor', N'APPLICATION', NEWID()),
(1, 2, N'UPDATE', N'AssigneeId', NULL, N'2', NULL, N'Orhan Ufuk Güleç', N'APPLICATION', NEWID()),
(3, 6, N'INSERT', NULL, NULL, NULL, NULL, NULL, N'API', NEWID());
GO

-- 21. TICKET ATTACHMENTS
INSERT INTO itsm.TicketAttachments (TicketId, UploadedByUserId, FileName, ContentType, FileSizeBytes, StorageProvider, StorageKey) VALUES
(1, 4, N'vpn_error_screenshot.png', N'image/png', 245760, N'LOCAL', N'/uploads/tickets/2026/10/vpn_error_screenshot.png'),
(2, 5, N'onay_belgesi.pdf', N'application/pdf', 1048576, N'AZURE_BLOB', N'tenant-itsm/tickets/2026/10/onay_belgesi.pdf'),
(3, 6, N'execution_plan.sql', N'application/sql', 15360, N'LOCAL', N'/uploads/tickets/2026/10/execution_plan.sql');
GO

-- 22. TICKET LINK TYPES
INSERT INTO itsm.TicketLinkTypes (Code, Name, IsActive) VALUES
(N'BLOCKS', N'Engelliyor / Engelleniyor', 1),
(N'RELATES', N'İlişkili Kayıt', 1),
(N'DUPLICATE', N'Aynı / Kopya Kayıt', 1);
GO

-- 23. TICKET LINKS
INSERT INTO itsm.TicketLinks (TicketId, RelatedTicketId, TicketLinkTypeId) VALUES
(3, 1, 2), -- ERP yavaşlığı ile VPN sorunu ilişkili
(2, 1, 3); -- Örnek bağlantı
GO

PRINT 'Kapsamlı dummy veriler başarıyla yüklendi.';
GO