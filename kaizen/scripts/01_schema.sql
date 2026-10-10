/* ============================================================
   SQL SERVER LABS
   KAIZEN MANAGEMENT (SÜREKLİ İYİLEŞTİRME) VERİTABANI - PRODUCTION ODAKLI ŞEMA
   ============================================================

   Hedef:
       Microsoft SQL Server 2022+

   Tasarım Prensipleri:
       - UTC zaman damgaları (SYSUTCDATETIME)
       - DATETIME2(3) veri tipi
       - İşlemsel varlıklar için BIGINT identity anahtarlar
       - İyimser eşzamanlılık (Optimistic Concurrency) için ROWVERSION
       - Süreç takibi ve maliyet/kazanç bütünlüğü
       - Esnek neden-sonuç (Kök Neden) ve aksiyon mimarisi

   ============================================================ */

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Veritabanı Oluşturma ve Hedefleme
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = N'Kaizen_DB')
BEGIN
    CREATE DATABASE Kaizen_DB;
END
GO

USE Kaizen_DB;
GO

-- 1. ŞEMALARIN OLUŞTURULMASI
CREATE SCHEMA org;
GO
CREATE SCHEMA kzn;
GO
CREATE SCHEMA audit;
GO

-- =========================================================================
-- 2. ORGANİZASYON VE KİMLİK YÖNETİMİ (org Şeması)
-- =========================================================================

-- Departmanlar Tablosu
CREATE TABLE org.Departments (
    DepartmentId BIGINT IDENTITY(1,1) NOT NULL,
    DepartmentCode VARCHAR(50) NOT NULL,
    DepartmentName NVARCHAR(150) NOT NULL,
    CostCenterCode VARCHAR(50) NULL,
    IsActive BIT DEFAULT 1 NOT NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_Departments PRIMARY KEY CLUSTERED (DepartmentId),
    CONSTRAINT UQ_Departments_Code UNIQUE NONCLUSTERED (DepartmentCode)
);
GO

-- Kullanıcılar / Çalışanlar Tablosu
CREATE TABLE org.Employees (
    EmployeeId BIGINT IDENTITY(1,1) NOT NULL,
    DepartmentId BIGINT NOT NULL,
    EmployeeNumber VARCHAR(50) NOT NULL,
    Email VARCHAR(255) NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    IsActive BIT DEFAULT 1 NOT NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_Employees PRIMARY KEY CLUSTERED (EmployeeId),
    CONSTRAINT UQ_Employees_Number UNIQUE NONCLUSTERED (EmployeeNumber),
    CONSTRAINT UQ_Employees_Email UNIQUE NONCLUSTERED (Email),
    CONSTRAINT FK_Employees_Departments FOREIGN KEY (DepartmentId) REFERENCES org.Departments(DepartmentId)
);
GO

-- Active Employee Lookup için Covering Index
CREATE NONCLUSTERED INDEX IX_Employees_Active_Lookup 
ON org.Employees (IsActive, DepartmentId) 
INCLUDE (EmployeeNumber, FirstName, LastName, Email);
GO


-- =========================================================================
-- 3. KAIZEN VE İYİLEŞTİRME YÖNETİMİ (kzn Şeması)
-- =========================================================================

-- Kaizen Önerileri / Projeleri Ana Tablosu
CREATE TABLE kzn.Kaizens (
    KaizenId BIGINT IDENTITY(1,1) NOT NULL,
    KaizenNumber VARCHAR(50) NOT NULL,
    DepartmentId BIGINT NOT NULL,
    ProposerId BIGINT NOT NULL,
    Title NVARCHAR(300) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    KaizenType VARCHAR(30) NOT NULL, -- 'INDIVIDUAL', 'TEAM', 'KOBETSU', 'MAJOR'
    Status VARCHAR(30) DEFAULT 'DRAFT' NOT NULL, -- 'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'IN_PROGRESS', 'COMPLETED', 'REJECTED'
    Priority VARCHAR(20) DEFAULT 'MEDIUM' NOT NULL, -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    TargetCompletionDate DATE NULL,
    ActualCompletionDate DATE NULL,
    RowVersion ROWVERSION NOT NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    UpdatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_Kaizens PRIMARY KEY CLUSTERED (KaizenId),
    CONSTRAINT UQ_Kaizens_Number UNIQUE NONCLUSTERED (KaizenNumber),
    CONSTRAINT FK_Kaizens_Departments FOREIGN KEY (DepartmentId) REFERENCES org.Departments(DepartmentId),
    CONSTRAINT FK_Kaizens_Proposer FOREIGN KEY (ProposerId) REFERENCES org.Employees(EmployeeId),
    CONSTRAINT CHK_Kaizens_Type CHECK (KaizenType IN ('INDIVIDUAL', 'TEAM', 'KOBETSU', 'MAJOR')),
    CONSTRAINT CHK_Kaizens_Status CHECK (Status IN ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'IN_PROGRESS', 'COMPLETED', 'REJECTED')),
    CONSTRAINT CHK_Kaizens_Priority CHECK (Priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);
GO

-- Aktif ve Durum Bazlı Filtrelenmiş Performans İndeksi
CREATE NONCLUSTERED INDEX IX_Kaizens_Status_Lookup 
ON kzn.Kaizens (Status, DepartmentId, UpdatedAt DESC)
INCLUDE (KaizenNumber, Title, ProposerId, KaizenType);
GO

-- Kaizen Ekip Üyeleri (Çoka-Çok İlişki)
CREATE TABLE kzn.KaizenTeamMembers (
    KaizenId BIGINT NOT NULL,
    EmployeeId BIGINT NOT NULL,
    MemberRole VARCHAR(30) DEFAULT 'MEMBER' NOT NULL, -- 'LEADER', 'MEMBER', 'SPONSOR'
    JoinedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_KaizenTeamMembers PRIMARY KEY CLUSTERED (KaizenId, EmployeeId),
    CONSTRAINT FK_TeamMembers_Kaizen FOREIGN KEY (KaizenId) REFERENCES kzn.Kaizens(KaizenId) ON DELETE CASCADE,
    CONSTRAINT FK_TeamMembers_Employee FOREIGN KEY (EmployeeId) REFERENCES org.Employees(EmployeeId),
    CONSTRAINT CHK_TeamMembers_Role CHECK (MemberRole IN ('LEADER', 'MEMBER', 'SPONSOR'))
);
GO

CREATE NONCLUSTERED INDEX IX_KaizenTeamMembers_Employee 
ON kzn.KaizenTeamMembers (EmployeeId) 
INCLUDE (KaizenId, MemberRole);
GO

-- Kök Neden Analizleri (Problem Detayları)
CREATE TABLE kzn.KaizenAnalyses (
    AnalysisId BIGINT IDENTITY(1,1) NOT NULL,
    KaizenId BIGINT NOT NULL,
    CurrentSituation NVARCHAR(MAX) NOT NULL,
    RootCauseDescription NVARCHAR(MAX) NOT NULL,
    AnalysisToolUsed VARCHAR(50) DEFAULT '5WHY' NOT NULL, -- '5WHY', 'FISHBONE', 'BRAINSTORMING', 'PARETO'
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_KaizenAnalyses PRIMARY KEY CLUSTERED (AnalysisId),
    CONSTRAINT UQ_KaizenAnalyses_Kaizen UNIQUE NONCLUSTERED (KaizenId),
    CONSTRAINT FK_Analyses_Kaizens FOREIGN KEY (KaizenId) REFERENCES kzn.Kaizens(KaizenId) ON DELETE CASCADE
);
GO

-- Aksiyon Planları (Faaliyet Adımları)
CREATE TABLE kzn.KaizenActionPlans (
    ActionId BIGINT IDENTITY(1,1) NOT NULL,
    KaizenId BIGINT NOT NULL,
    AssignedToId BIGINT NOT NULL,
    ActionDescription NVARCHAR(500) NOT NULL,
    DueDate DATE NOT NULL,
    IsCompleted BIT DEFAULT 0 NOT NULL,
    CompletionDate DATETIME2(3) NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_KaizenActionPlans PRIMARY KEY CLUSTERED (ActionId),
    CONSTRAINT FK_ActionPlans_Kaizens FOREIGN KEY (KaizenId) REFERENCES kzn.Kaizens(KaizenId) ON DELETE CASCADE,
    CONSTRAINT FK_ActionPlans_Assignee FOREIGN KEY (AssignedToId) REFERENCES org.Employees(EmployeeId)
);
GO

-- Tamamlanmamış Aksiyonlar İçin Partial (Filtered) Index
CREATE NONCLUSTERED INDEX IX_ActionPlans_Pending 
ON kzn.KaizenActionPlans (AssignedToId, DueDate)
INCLUDE (KaizenId, ActionDescription)
WHERE IsCompleted = 0;
GO

-- Sonuç ve Kazanım Takibi (Ölçümleme)
CREATE TABLE kzn.KaizenResults (
    ResultId BIGINT IDENTITY(1,1) NOT NULL,
    KaizenId BIGINT NOT NULL,
    FinancialGain DECIMAL(18,2) DEFAULT 0.00 NOT NULL, -- Tasarruf / Kazanç Miktarı
    CurrencyCode VARCHAR(3) DEFAULT 'TRY' NOT NULL,
    TimeSavedHours DECIMAL(10,2) DEFAULT 0.00 NOT NULL, -- Zaman Tasarrufu (Saat)
    SafetyImprovementScore INT DEFAULT 0 NOT NULL,     -- İSG İyileştirme Puanı
    QualityImprovementDescription NVARCHAR(MAX) NULL,
    IsVerifiedByManager BIT DEFAULT 0 NOT NULL,
    VerificationDate DATETIME2(3) NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_KaizenResults PRIMARY KEY CLUSTERED (ResultId),
    CONSTRAINT UQ_KaizenResults_Kaizen UNIQUE NONCLUSTERED (KaizenId),
    CONSTRAINT FK_Results_Kaizens FOREIGN KEY (KaizenId) REFERENCES kzn.Kaizens(KaizenId) ON DELETE CASCADE
);
GO


-- =========================================================================
-- 4. AUDIT VE TARİHÇE LOGLARI (audit Şeması)
-- =========================================================================

CREATE TABLE audit.KaizenLogs (
    LogId BIGINT IDENTITY(1,1) NOT NULL,
    KaizenId BIGINT NOT NULL,
    EmployeeId BIGINT NOT NULL,
    ActionType VARCHAR(50) NOT NULL, -- 'CREATED', 'STATUS_CHANGED', 'ACTION_ADDED', 'RESULT_VERIFIED'
    OldValue NVARCHAR(200) NULL,
    NewValue NVARCHAR(200) NULL,
    IpAddress VARCHAR(45) NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_KaizenLogs PRIMARY KEY CLUSTERED (LogId),
    CONSTRAINT FK_Audit_Kaizens FOREIGN KEY (KaizenId) REFERENCES kzn.Kaizens(KaizenId) ON DELETE CASCADE,
    CONSTRAINT FK_Audit_Employees FOREIGN KEY (EmployeeId) REFERENCES org.Employees(EmployeeId)
);
GO

CREATE NONCLUSTERED INDEX IX_Audit_KaizenTimeline 
ON audit.KaizenLogs (KaizenId, CreatedAt DESC)
INCLUDE (ActionType, EmployeeId, OldValue, NewValue);
GO