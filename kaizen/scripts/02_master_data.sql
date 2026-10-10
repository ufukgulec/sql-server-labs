/* ============================================================
   KAIZEN MANAGEMENT VERİTABANI - MASTER (ANA) VERİLER
   ============================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

USE Kaizen_DB;
GO

-- 1. KURUMSAL TEMEL DEPARTMANLAR (org.Departments)
INSERT INTO org.Departments (DepartmentCode, DepartmentName, CostCenterCode, IsActive)
VALUES 
('DEP_PROD', N'Üretim Departmanı', 'CC-1001', 1),
('DEP_QUAL', N'Kalite Güvence', 'CC-1002', 1),
('DEP_MAINT', N'Bakım ve Onarım', 'CC-1003', 1),
('DEP_RD', N'Ar-Ge ve Mühendislik', 'CC-1004', 1),
('DEP_HR', N'İnsan Kaynakları', 'CC-2001', 1),
('DEP_FIN', N'Finans ve Muhasebe', 'CC-2002', 1);
GO

-- 2. SİSTEM VE OPERASYONEL ÇALIŞANLAR (org.Employees)
INSERT INTO org.Employees (DepartmentId, EmployeeNumber, Email, FirstName, LastName, IsActive)
VALUES 
(1, 'EMP-0001', 'admin.kaizen@company.com', N'Sistem', N'Yönetici', 1),
(1, 'EMP-1001', 'ahmet.yilmaz@company.com', N'Ahmet', N'Yılmaz', 1),
(2, 'EMP-1002', 'ayse.demir@company.com', N'Ayşe', N'Demir', 1),
(3, 'EMP-1003', 'mehmet.kaya@company.com', N'Mehmet', N'Kaya', 1),
(4, 'EMP-1004', 'fatma.celik@company.com', N'Fatma', N'Çelik', 1),
(5, 'EMP-2001', 'can.ozturk@company.com', N'Can', N'Öztürk', 1);
GO

-- 3. ÖRNEK KAIZEN PROJELERİ / ÖNERİLERİ (kzn.Kaizens)
INSERT INTO kzn.Kaizens (KaizenNumber, DepartmentId, ProposerId, Title, Description, KaizenType, Status, Priority, TargetCompletionDate)
VALUES 
('KZN-2026-0001', 1, 2, N'Montaj Hattı Ergonomi ve Malzeme Yerleşimi İyileştirmesi', N'Montaj hattındaki parça tepsilerinin operatörün bel hizasına getirilmesiyle eğilme hareketleri azaltılacak.', 'INDIVIDUAL', 'IN_PROGRESS', 'HIGH', '2026-05-15'),
('KZN-2026-0002', 2, 3, N'Kalite Kontrol Ölçüm Sürecinde Otomasyon', N'Manuel ölçüm kayıtlarının dijitalleştirilmesi ile hata oranının düşürülmesi ve raporlama hızının artırılması.', 'TEAM', 'APPROVED', 'CRITICAL', '2026-06-30'),
('KZN-2026-0003', 3, 4, N'Pres Makinesi Kalıp Değişim Süreçlerinin (SMED) Hızlandırılması', N'Kalıp değişim ekipmanlarının standartlaştırılması ve harici hazırlık oranının artırılması.', 'KOBETSU', 'SUBMITTED', 'MEDIUM', '2026-07-10');
GO

-- 4. KAIZEN EKİP ÜYELERİ ATAMALARI (kzn.KaizenTeamMembers)
INSERT INTO kzn.KaizenTeamMembers (KaizenId, EmployeeId, MemberRole)
VALUES 
(1, 2, 'LEADER'),
(2, 3, 'LEADER'),
(2, 4, 'MEMBER'),
(3, 4, 'LEADER'),
(3, 2, 'MEMBER');
GO

-- 5. KÖK NEDEN ANALİZLERİ (kzn.KaizenAnalyses)
INSERT INTO kzn.KaizenAnalyses (KaizenId, CurrentSituation, RootCauseDescription, AnalysisToolUsed)
VALUES 
(1, N'Operatörler günde ortalama 300 kez eğilerek malzeme alıyor, bu da yorgunluğa ve zaman kaybına yol açıyor.', N'Malzeme sehpalarının sabit ve ergonomik olmayan yükseklikte konumlandırılmış olması.', '5WHY'),
(2, N'Ölçüm verileri kağıt ortamında tutulduğu için veri giriş gecikmeleri yaşanıyor.', N'Dijital entegrasyon eksikliği ve manuel süreç bağımlılığı.', 'FISHBONE');
GO

-- 6. AKSİYON PLANLARI (kzn.KaizenActionPlans)
INSERT INTO kzn.KaizenActionPlans (KaizenId, AssignedToId, ActionDescription, DueDate, IsCompleted)
VALUES 
(1, 2, N'Ergonomik sehpa tasarımı çizimlerinin tamamlanması', '2026-04-20', 1),
(1, 3, N'Yeni sehpaların imalatı ve hatta montajı', '2026-05-05', 0),
(2, 4, N'Ölçüm arayüz yazılımı gereksinim analizinin yapılması', '2026-05-10', 0);
GO

-- 7. SONUÇ VE KAZANIM ÖLÇÜMLERİ (kzn.KaizenResults)
INSERT INTO kzn.KaizenResults (KaizenId, FinancialGain, CurrencyCode, TimeSavedHours, SafetyImprovementScore, QualityImprovementDescription, IsVerifiedByManager)
VALUES 
(1, 15000.00, 'TRY', 120.50, 4, N'Operatör bel zorlanması riski ortadan kaldırıldı, verimlilik artışı sağlandı.', 1);
GO