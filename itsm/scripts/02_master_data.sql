/* ============================================================
   ITSM VERİTABANI - MASTER (ANA) VERİLER
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

PRINT 'Master (Ana) veriler yükleniyor...';
GO

-- 1. DEPARTMENTS (Parametre / Tanım)
INSERT INTO itsm.Departments (Code, Name, IsActive) VALUES
(N'IT', N'Bilgi Teknolojileri', 1),
(N'HR', N'İnsan Kaynakları', 1),
(N'FIN', N'Finans ve Muhasebe', 1),
(N'OPS', N'Operasyon ve Destek', 1),
(N'SALES', N'Satış ve Pazarlama', 1);
GO

-- 2. ROLES (Parametre / Tanım)
INSERT INTO itsm.Roles (Code, Name, IsActive) VALUES
(N'SUPER_ADMIN', N'Süper Yönetici', 1),
(N'IT_SUPPORT', N'IT Destek Personeli', 1),
(N'DEPARTMENT_MANAGER', N'Departman Yöneticisi', 1),
(N'END_USER', N'Son Kullanıcı', 1);
GO

-- 3. TICKET TYPES (Parametre / Tanım)
INSERT INTO itsm.TicketTypes (Code, Name, IsActive) VALUES
(N'INCIDENT', N'Arıza / Olay (Incident)', 1),
(N'SERVICE_REQUEST', N'Hizmet Talebi (Request)', 1),
(N'PROBLEM', N'Problem Yönetimi', 1),
(N'CHANGE', N'Değişiklik Talebi (Change)', 1);
GO

-- 4. TICKET STATUSES (Parametre / Tanım)
INSERT INTO itsm.TicketStatuses (Code, Name, IsClosed, SortOrder, IsActive) VALUES
(N'NEW', N'Yeni', 0, 10, 1),
(N'IN_PROGRESS', N'Üzerinde Çalışılıyor', 0, 20, 1),
(N'PENDING', N'Beklemede', 0, 30, 1),
(N'RESOLVED', N'Çözüldü', 1, 40, 1),
(N'CLOSED', N'Kapatıldı', 1, 50, 1),
(N'CANCELLED', N'İptal Edildi', 1, 60, 1);
GO

-- 5. TICKET PRIORITIES (Parametre / Tanım)
INSERT INTO itsm.TicketPriorities (Code, Name, PriorityLevel, IsActive) VALUES
(N'LOW', N'Düşük', 2, 1),
(N'MEDIUM', N'Normal', 5, 1),
(N'HIGH', N'Yüksek', 8, 1),
(N'CRITICAL', N'Kritik / Acil', 10, 1);
GO

-- 6. TICKET STATUS TRANSITIONS (Parametre / Tanım)
INSERT INTO itsm.TicketStatusTransitions (FromStatusId, ToStatusId, IsActive) VALUES
(1, 2, 1),
(2, 3, 1),
(3, 2, 1),
(2, 4, 1),
(4, 5, 1),
(1, 6, 1);
GO

-- 7. TICKET LINK TYPES (Parametre / Tanım)
INSERT INTO itsm.TicketLinkTypes (Code, Name, IsActive) VALUES
(N'BLOCKS', N'Engelliyor / Engelleniyor', 1),
(N'RELATES', N'İlişkili Kayıt', 1),
(N'DUPLICATE', N'Aynı / Kopya Kayıt', 1);
GO

-- 8. SLA POLICIES (Parametre / Tanım)
INSERT INTO itsm.SlaPolicies (Code, Name, ResponseTimeMin, ResolutionTimeMin, IsActive) VALUES
(N'SLA_CRITICAL', N'Kritik Seviye SLA (15dk / 2 Saat)', 15, 120, 1),
(N'SLA_STANDARD', N'Standart SLA (60dk / 24 Saat)', 60, 1440, 1),
(N'SLA_LOW', N'Düşük Öncelik SLA (240dk / 72 Saat)', 240, 4320, 1);
GO

-- 9. TAGS (Parametre / Tanım)
INSERT INTO itsm.Tags (Name, IsActive) VALUES
(N'Donanım', 1),
(N'Acil', 1),
(N'ERP', 1),
(N'VPN', 1),
(N'Lisans', 1),
(N'Yazıcı', 1),
(N'E-Posta', 1);
GO

PRINT 'Master (Ana) veriler başarıyla yüklendi.';
GO