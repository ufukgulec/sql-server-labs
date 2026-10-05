/* ============================================================
   ITSM VERİTABANI - GELİŞMİŞ DUMMY (TEST) VERİ SETİ
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

PRINT 'Gelişmiş test verileri yükleniyor...';
GO

-- 1. USERS (Gerçekçi Kullanıcı Profilleri)
INSERT INTO itsm.Users (Username, FirstName, LastName, Email, DepartmentId, IsActive) VALUES
(N'admin', N'System', N'Admin', N'admin@itsm.local', 1, 1),
(N'ufuk.gulec', N'Orhan Ufuk', N'Güleç', N'ufuk.gulec@itsm.local', 1, 1),
(N'ahmet.yilmaz', N'Ahmet', N'Yılmaz', N'ahmet.yilmaz@itsm.local', 1, 1),
(N'ayse.demir', N'Ayşe', N'Demir', N'ayse.demir@itsm.local', 2, 1),
(N'mehmet.kaya', N'Mehmet', N'Kaya', N'mehmet.kaya@itsm.local', 3, 1),
(N'zeynep.celik', N'Zeynep', N'Çelik', N'zeynep.celik@itsm.local', 4, 1),
(N'can.polat', N'Can', N'Polat', N'can.polat@itsm.local', 5, 1),
(N'elif.sahin', N'Elif', N'Şahin', N'elif.sahin@itsm.local', 2, 1);
GO

-- 2. USER ROLES (Kullanıcı Rol Atamaları)
INSERT INTO itsm.UserRoles (UserId, RoleId) VALUES
(1, 1), -- admin -> Süper Admin
(2, 2), -- ufuk.gulec -> IT Destek
(3, 2), -- ahmet.yilmaz -> IT Destek
(4, 3), -- ayse.demir -> Departman Yöneticisi
(5, 4), -- mehmet.kaya -> Son Kullanıcı
(6, 4), -- zeynep.celik -> Son Kullanıcı
(7, 4), -- can.polat -> Son Kullanıcı
(8, 3); -- elif.sahin -> Departman Yöneticisi
GO

-- 3. CATEGORIES (Hiyerarşik Yapı)
INSERT INTO itsm.Categories (ParentCategoryId, Code, Name, IsActive) VALUES
(NULL, N'HW', N'Donanım', 1),
(NULL, N'SW', N'Yazılım', 1),
(NULL, N'NET', N'Ağ ve İnternet', 1),
(NULL, N'ACC', N'Yetki ve Hesaplar', 1);

INSERT INTO itsm.Categories (ParentCategoryId, Code, Name, IsActive) VALUES
(1, N'HW_PC', N'Masaüstü / Laptop Arızası', 1),
(1, N'HW_PRN', N'Yazıcı ve Tarayıcı', 1),
(2, N'SW_OFFICE', N'Office 365 / Lisans', 1),
(2, N'SW_ERP', N'ERP / Muhasebe Yazılımı', 1),
(3, N'NET_VPN', N'VPN Bağlantı Sorunları', 1),
(4, N'ACC_PASS', N'Şifre Sıfırlama ve Hesap Kilidi', 1);
GO

-- 4. SERVICES (IT Servisleri)
INSERT INTO itsm.Services (Code, Name, OwnerUserId, IsActive) VALUES
(N'SRV_ERP', N'Kurumsal ERP Sistemi', 2, 1),
(N'SRV_MAIL', N'E-Posta Hizmetleri', 3, 1),
(N'SRV_PRINT', N'Ortak Yazıcı Havuzu', 3, 1),
(N'SRV_VPN', N'Uzak Bağlantı (VPN) Altyapısı', 2, 1);
GO

-- 5. ASSIGNMENT GROUPS (Destek Ekipleri)
INSERT INTO itsm.AssignmentGroups (Code, Name, ManagerUserId, IsActive) VALUES
(N'GRP_HELPCORE', N'1. Seviye Destek Masası', 2, 1),
(N'GRP_SYSADMIN', N'Sistem ve Ağ Yönetimi', 3, 1),
(N'GRP_DEV', N'Yazılım Geliştirme Ekibi', 2, 1);
GO

-- 6. ASSIGNMENT GROUP MEMBERS (Ekip Üyelikleri)
INSERT INTO itsm.AssignmentGroupMembers (AssignmentGroupId, UserId) VALUES
(1, 2), -- Ufuk -> 1. Seviye
(1, 3), -- Ahmet -> 1. Seviye
(2, 3), -- Ahmet -> Sistem Yöneticisi
(3, 2); -- Ufuk -> Yazılım Ekibi
GO

-- 7. TICKETS (Gerçekçi Ticket Senaryoları)
INSERT INTO itsm.Tickets 
(
    Subject, Description, TicketTypeId, TicketStatusId, TicketPriorityId, 
    CategoryId, ServiceId, DepartmentId, RequesterId, AssignmentGroupId, AssigneeId, SlaPolicyId, DueAt
) 
VALUES
(
    N'VPN bağlantısı kopuyor ve bağlanamıyorum', 
    N'Şirket dışından VPN ile bağlanmaya çalışırken kimlik doğrulama hatası alıyorum.',
    1, 2, 3, 9, 4, 2, 4, 1, 2, 1, DATEADD(hour, 4, SYSUTCDATETIME())
),
(
    N'Yeni bilgisayar kurulum talebi', 
    N'Departmanımıza yeni katılan personel için dizüstü bilgisayar talep ediyorum.',
    2, 1, 2, 5, 1, 3, 5, 3, NULL, 2, DATEADD(day, 2, SYSUTCDATETIME())
),
(
    N'ERP Rapor ekranı yavaş çalışıyor', 
    N'Ay sonu mutabakat raporunu alırken sistem kilitleniyor ve timeout alıyoruz.',
    1, 2, 4, 8, 1, 3, 3, 1, 3, 1, DATEADD(hour, 2, SYSUTCDATETIME())
),
(
    N'Outlook e-posta alıp göndermede sorun yaşanıyor', 
    N'Sabah saatlerinden beri maillerime düşen yeni iletiler güncellenmiyor.',
    1, 1, 3, 2, 2, 5, 7, 1, NULL, 2, DATEADD(hour, 6, SYSUTCDATETIME())
),
(
    N'Mali işler yazıcısı kağıt sıkıştırıyor', 
    N'Finans departmanındaki ana yazıcı çıktı alırken sürekli hata veriyor.',
    1, 3, 2, 6, 3, 3, 5, 1, 2, 2, DATEADD(day, 1, SYSUTCDATETIME())
);
GO

-- 8. TICKET COMMENTS (Bilet Yorumları / Yazışmalar)
INSERT INTO itsm.TicketComments (TicketId, UserId, Comment, IsInternal) VALUES
(1, 2, N'Kullanıcı sertifikaları kontrol edildi, yenilenmesi gerekiyor.', 1),
(1, 4, N'Ne zaman çözülür acaba? Acil desteğe ihtiyacım var.', 0),
(3, 3, N'İlgili SQL sorgusu için execution plan inceleniyor.', 1),
(5, 2, N'Yazıcı silindiri temizlendi, test çıktısı bekleniyor.', 1);
GO

-- 9. TICKET TAGS (Bilet Etiketleri)
INSERT INTO itsm.TicketTags (TicketId, TagId) VALUES
(1, 4), (1, 2),
(2, 1),
(3, 3), (3, 2),
(4, 7),
(5, 1), (5, 6);
GO

-- 10. TICKET WATCHERS (İzleyiciler)
INSERT INTO itsm.TicketWatchers (TicketId, UserId) VALUES
(1, 2), (1, 3),
(3, 2), (3, 4),
(4, 3);
GO

-- 11. TICKET WORKLOGS (Efor / Çalışma Kayıtları)
INSERT INTO itsm.TicketWorkLogs (TicketId, UserId, StartedAt, EndedAt, DurationMinutes, Description, IsBillable) VALUES
(1, 2, DATEADD(minute, -90, SYSUTCDATETIME()), DATEADD(minute, -30, SYSUTCDATETIME()), 60, N'VPN Log analizi yapıldı.', 1),
(3, 3, DATEADD(minute, -180, SYSUTCDATETIME()), DATEADD(minute, -120, SYSUTCDATETIME()), 60, N'Index optimizasyonu yapıldı.', 1),
(5, 2, DATEADD(minute, -40, SYSUTCDATETIME()), DATEADD(minute, -10, SYSUTCDATETIME()), 30, N'Fiziksel donanım kontrolü ve temizlik.', 0);
GO

-- 12. TICKET HISTORY / AUDIT (Değişiklik Tarihçesi)
INSERT INTO itsm.TicketHistory (TicketId, UserId, ActionType, FieldName, OldValue, NewValue, OldDisplayValue, NewDisplayValue, Source, CorrelationId) VALUES
(1, 4, N'INSERT', NULL, NULL, NULL, NULL, NULL, N'APPLICATION', NEWID()),
(1, 2, N'UPDATE', N'TicketStatusId', N'1', N'2', N'Yeni', N'Üzerinde Çalışılıyor', N'APPLICATION', NEWID()),
(1, 2, N'UPDATE', N'AssigneeId', NULL, N'2', NULL, N'Orhan Ufuk Güleç', N'APPLICATION', NEWID()),
(3, 6, N'INSERT', NULL, NULL, NULL, NULL, NULL, N'API', NEWID()),
(5, 5, N'INSERT', NULL, NULL, NULL, NULL, NULL, N'APPLICATION', NEWID());
GO

-- 13. TICKET ATTACHMENTS (Dosya Ekleri)
INSERT INTO itsm.TicketAttachments (TicketId, UploadedByUserId, FileName, ContentType, FileSizeBytes, StorageProvider, StorageKey) VALUES
(1, 4, N'vpn_error_screenshot.png', N'image/png', 245760, N'LOCAL', N'/uploads/tickets/2026/10/vpn_error_screenshot.png'),
(2, 5, N'onay_belgesi.pdf', N'application/pdf', 1048576, N'AZURE_BLOB', N'tenant-itsm/tickets/2026/10/onay_belgesi.pdf'),
(3, 6, N'execution_plan.sql', N'application/sql', 15360, N'LOCAL', N'/uploads/tickets/2026/10/execution_plan.sql'),
(5, 5, N'yazici_hata_isigi.jpg', N'image/jpeg', 512000, N'LOCAL', N'/uploads/tickets/2026/10/yazici_hata_isigi.jpg');
GO

-- 14. TICKET LINKS (Biletler Arası İlişkiler)
INSERT INTO itsm.TicketLinks (TicketId, RelatedTicketId, TicketLinkTypeId) VALUES
(3, 1, 2), -- ERP yavaşlığı ile VPN sorunu ilişkili
(2, 1, 3);
GO

PRINT 'Gelişmiş test verileri başarıyla yüklendi.';
GO