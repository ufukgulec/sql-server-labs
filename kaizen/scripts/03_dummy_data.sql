/* ============================================================
   KAIZEN MANAGEMENT VERİTABANI - GELİŞMİŞ DUMMY (TEST) VERİ SETİ
   ============================================================ */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

USE Kaizen_DB;
GO

-- 1. EK TEST ÇALIŞANLARI (org.Employees) - Çakışmasız Numaralar
INSERT INTO org.Employees (DepartmentId, EmployeeNumber, Email, FirstName, LastName, IsActive)
VALUES 
(1, 'EMP-3001', 'burak.yilmaz@company.com', N'Burak', N'Yılmaz', 1),
(1, 'EMP-3002', 'deniz.arslan@company.com', N'Deniz', N'Arslan', 1),
(2, 'EMP-3003', 'sibel.aydin@company.com', N'Sibel', N'Aydın', 1),
(3, 'EMP-3004', 'hakan.unal@company.com', N'Hakan', N'Ünal', 1),
(4, 'EMP-3005', 'elif.polat@company.com', N'Elif', N'Polat', 1),
(5, 'EMP-3006', 'murat.guler@company.com', N'Murat', N'Güler', 0);
GO

-- 2. EK KAIZEN PROJELERİ / ÖNERİLERİ (kzn.Kaizens)
-- Master veride 3 kayıt olduğu için Id'ler 4, 5, 6 olarak devam eder. ProposerId'ler yeni eklenen çalışanlara (7-12) bağlanır.
INSERT INTO kzn.Kaizens (KaizenNumber, DepartmentId, ProposerId, Title, Description, KaizenType, Status, Priority, TargetCompletionDate, ActualCompletionDate)
VALUES 
('KZN-2026-0004', 1, 7, N'Hattaki Kaçak Basınçlı Hava Tüketiminin Azaltılması', N'Ana hat üzerindeki kaçakların tespiti ve pnömatik bağlantıların yenilenmesiyle enerji tasarrufu sağlanması.', 'TEAM', 'COMPLETED', 'HIGH', '2026-03-30', '2026-03-25'),
('KZN-2026-0005', 4, 10, N'Prototip Üretim Süreçlerinde 3D Yazıcı Kullanımının Yaygınlaştırılması', N'Örnek kalıp üretim sürelerini kısaltmak amacıyla tasarımların doğrudan 3D baskıya alınması.', 'INDIVIDUAL', 'APPROVED', 'MEDIUM', '2026-08-15', NULL),
('KZN-2026-0006', 2, 8, N'Girdi Kalite Kontrol Sürecinde Dijital Barkod Entegrasyonu', N'Tedarikçiden gelen hammaddelerin barkod okutularak sisteme anlık işlenmesi.', 'MAJOR', 'UNDER_REVIEW', 'CRITICAL', '2026-09-01', NULL);
GO

-- 3. EK KAIZEN EKİP ÜYELERİ ATAMALARI (kzn.KaizenTeamMembers)
-- KaizenId 4, 5 ve 6 için atamalar
INSERT INTO kzn.KaizenTeamMembers (KaizenId, EmployeeId, MemberRole)
VALUES 
(4, 7, 'LEADER'),
(4, 9, 'MEMBER'),
(5, 10, 'LEADER'),
(6, 8, 'LEADER'),
(6, 2, 'SPONSOR');
GO

-- 4. EK KÖK NEDEN ANALİZLERİ (kzn.KaizenAnalyses)
INSERT INTO kzn.KaizenAnalyses (KaizenId, CurrentSituation, RootCauseDescription, AnalysisToolUsed)
VALUES 
(4, N'Kompresörlerin sürekli devreye girmesi yüksek enerji tüketimine neden oluyor.', N'Eski tip rakorlar ve hat birleşim yerlerindeki mikro kaçaklar.', 'FISHBONE'),
(5, N'Örnek kalıp üretimi dış tedarikçiler nedeniyle ortalama 10 gün sürüyor.', N'Kurum içi hızlı prototipleme imkanlarının yetersiz olması.', 'BRAIN_STORMING');
GO

-- 5. EK AKSİYON PLANLARI (kzn.KaizenActionPlans)
INSERT INTO kzn.KaizenActionPlans (KaizenId, AssignedToId, ActionDescription, DueDate, IsCompleted, CompletionDate)
VALUES 
(4, 7, N'Ultrasonik kaçak dedektörü ile tüm hattın taranması', '2026-03-10', 1, '2026-03-08'),
(4, 9, N'Arızalı rakorların değişimi', '2026-03-20', 1, '2026-03-22'),
(5, 10, N'Endüstriyel 3D yazıcı tekliflerinin toplanması ve fizibilite', '2026-06-01', 0, NULL),
(6, 8, N'El terminali yazılım gereksinimlerinin çıkarılması', '2026-07-15', 0, NULL);
GO

-- 6. EK SONUÇ VE KAZANIM ÖLÇÜMLERİ (kzn.KaizenResults)
INSERT INTO kzn.KaizenResults (KaizenId, FinancialGain, CurrencyCode, TimeSavedHours, SafetyImprovementScore, QualityImprovementDescription, IsVerifiedByManager, VerificationDate)
VALUES 
(4, 42500.00, 'TRY', 45.00, 3, N'Basçınçlı hava kayıpları engellendi, enerji maliyetinde yıllık %15 düşüş sağlandı.', 1, '2026-03-28');
GO

-- 7. AUDIT VE TARİHÇE LOGLARI (audit.KaizenLogs)
INSERT INTO audit.KaizenLogs (KaizenId, EmployeeId, ActionType, OldValue, NewValue, IpAddress)
VALUES 
(1, 2, 'CREATED', NULL, 'DRAFT', '192.168.10.15'),
(1, 2, 'STATUS_CHANGED', 'DRAFT', 'IN_PROGRESS', '192.168.10.15'),
(4, 7, 'CREATED', NULL, 'DRAFT', '192.168.10.42'),
(4, 7, 'STATUS_CHANGED', 'IN_PROGRESS', 'COMPLETED', '192.168.10.42'),
(4, 1, 'RESULT_VERIFIED', 'False', 'True', '192.168.10.10');
GO