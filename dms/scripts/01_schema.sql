/* ============================================================
   SQL SERVER LABS
   DMS (DOCUMENT MANAGEMENT SYSTEM) VERİTABANI - PRODUCTION ODAKLI ŞEMA
   ============================================================

   Hedef:
       Microsoft SQL Server 2022+

   Tasarım Prensipleri:
       - UTC zaman damgaları (SYSUTCDATETIME)
       - DATETIME2(3) veri tipi
       - İşlemsel varlıklar için BIGINT identity anahtarlar
       - İyimser eşzamanlılık (Optimistic Concurrency) için ROWVERSION
       - Değiştirilemez (Immutable) versiyonlama ve SHA-256 bütünlük doğrulaması
       - HIERARCHYID tabanlı klasör hiyerarşisi
       - Esnek ACL ve Key-Value Metadata mimarisi

   ============================================================ */

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Veritabanı Oluşturma ve Hedefleme
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = N'DMS_DB')
BEGIN
    CREATE DATABASE DMS_DB;
END
GO

USE DMS_DB;
GO

-- 1. ŞEMALARIN OLUŞTURULMASI
CREATE SCHEMA sec;
GO
CREATE SCHEMA dms;
GO
CREATE SCHEMA audit;
GO

-- =========================================================================
-- 2. KİMLİK VE YETKİLENDİRME (sec Şeması)
-- =========================================================================

-- Kullanıcılar Tablosu
CREATE TABLE sec.Users (
    UserId BIGINT IDENTITY(1,1) NOT NULL,
    Username VARCHAR(100) NOT NULL,
    Email VARCHAR(255) NOT NULL,
    PasswordHash VARCHAR(256) NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    IsActive BIT DEFAULT 1 NOT NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId),
    CONSTRAINT UQ_Users_Username UNIQUE NONCLUSTERED (Username),
    CONSTRAINT UQ_Users_Email UNIQUE NONCLUSTERED (Email)
);
GO

-- Login/Authentication sorguları için kapsayıcı (Covering) Filtered Index
CREATE NONCLUSTERED INDEX IX_Users_Active_Auth 
ON sec.Users (Username, IsActive) 
INCLUDE (PasswordHash, Email, FirstName, LastName)
WHERE IsActive = 1;
GO

-- Gruplar / Departmanlar
CREATE TABLE sec.Groups (
    GroupId BIGINT IDENTITY(1,1) NOT NULL,
    GroupCode VARCHAR(50) NOT NULL,
    GroupName NVARCHAR(150) NOT NULL,
    Description NVARCHAR(500) NULL,
    IsActive BIT DEFAULT 1 NOT NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_Groups PRIMARY KEY CLUSTERED (GroupId),
    CONSTRAINT UQ_Groups_Code UNIQUE NONCLUSTERED (GroupCode)
);
GO

-- Kullanıcı - Grup Çoka-Çok İlişkisi
CREATE TABLE sec.UserGroups (
    UserId BIGINT NOT NULL,
    GroupId BIGINT NOT NULL,
    JoinedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_UserGroups PRIMARY KEY CLUSTERED (UserId, GroupId),
    CONSTRAINT FK_UserGroups_Users FOREIGN KEY (UserId) REFERENCES sec.Users(UserId),
    CONSTRAINT FK_UserGroups_Groups FOREIGN KEY (GroupId) REFERENCES sec.Groups(GroupId)
);
GO

CREATE NONCLUSTERED INDEX IX_UserGroups_GroupId 
ON sec.UserGroups (GroupId) 
INCLUDE (UserId);
GO


-- =========================================================================
-- 3. DOKÜMAN VE KLASÖR YÖNETİMİ (dms Şeması)
-- =========================================================================

-- Klasör Hiyerarşisi (HierarchyId Tabanlı)
CREATE TABLE dms.Folders (
    FolderId BIGINT IDENTITY(1,1) NOT NULL,
    Node HIERARCHYID NOT NULL,
    Level AS Node.GetLevel() PERSISTED,
    FolderName NVARCHAR(255) NOT NULL,
    CreatedBy BIGINT NOT NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    IsActive BIT DEFAULT 1 NOT NULL,
    
    CONSTRAINT PK_Folders PRIMARY KEY CLUSTERED (FolderId),
    CONSTRAINT UQ_Folders_Node UNIQUE NONCLUSTERED (Node),
    CONSTRAINT FK_Folders_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES sec.Users(UserId)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_Folders_BreadthFirst 
ON dms.Folders (Level, Node)
INCLUDE (FolderName, IsActive);
GO

-- Doküman Ana Tablosu
CREATE TABLE dms.Documents (
    DocumentId BIGINT IDENTITY(1,1) NOT NULL,
    FolderId BIGINT NOT NULL,
    DocumentNumber VARCHAR(50) NOT NULL,
    Title NVARCHAR(500) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    CurrentVersionId BIGINT NULL, 
    OwnerId BIGINT NOT NULL,
    IsLocked BIT DEFAULT 0 NOT NULL,
    LockedBy BIGINT NULL,
    IsDeleted BIT DEFAULT 0 NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    UpdatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_Documents PRIMARY KEY CLUSTERED (DocumentId),
    CONSTRAINT UQ_DocumentNumber UNIQUE NONCLUSTERED (DocumentNumber),
    CONSTRAINT FK_Documents_Folders FOREIGN KEY (FolderId) REFERENCES dms.Folders(FolderId),
    CONSTRAINT FK_Documents_Owner FOREIGN KEY (OwnerId) REFERENCES sec.Users(UserId),
    CONSTRAINT FK_Documents_LockedBy FOREIGN KEY (LockedBy) REFERENCES sec.Users(UserId)
);
GO

CREATE NONCLUSTERED INDEX IX_Documents_Active 
ON dms.Documents (FolderId, UpdatedAt DESC)
INCLUDE (DocumentNumber, Title, CurrentVersionId)
WHERE IsDeleted = 0;
GO

-- Doküman Versiyonları (Immutable)
CREATE TABLE dms.DocumentVersions (
    VersionId BIGINT IDENTITY(1,1) NOT NULL,
    DocumentId BIGINT NOT NULL,
    VersionMajor INT NOT NULL,
    VersionMinor INT NOT NULL,
    StorageProvider VARCHAR(50) NOT NULL,
    FilePath VARCHAR(1000) NOT NULL,
    FileSizeKB BIGINT NOT NULL,
    FileExtension VARCHAR(10) NOT NULL,
    FileHash VARCHAR(64) NOT NULL,
    ChangeLog NVARCHAR(1000) NULL,
    UploadedBy BIGINT NOT NULL,
    UploadedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_DocumentVersions PRIMARY KEY CLUSTERED (VersionId),
    CONSTRAINT UQ_DocumentVersions_Version UNIQUE NONCLUSTERED (DocumentId, VersionMajor, VersionMinor),
    CONSTRAINT FK_Versions_Documents FOREIGN KEY (DocumentId) REFERENCES dms.Documents(DocumentId),
    CONSTRAINT FK_Versions_UploadedBy FOREIGN KEY (UploadedBy) REFERENCES sec.Users(UserId)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_DocumentVersions_Lookup 
ON dms.DocumentVersions (DocumentId, VersionMajor DESC, VersionMinor DESC)
INCLUDE (FilePath, FileHash);
GO

-- Circular Dependency Önlemek İçin CurrentVersionId FK Bağlantısı
ALTER TABLE dms.Documents
ADD CONSTRAINT FK_Documents_CurrentVersion FOREIGN KEY (CurrentVersionId) REFERENCES dms.DocumentVersions(VersionId);
GO

-- Dinamik Metadata / Etiketler (Key-Value)
CREATE TABLE dms.DocumentMetadata (
    DocumentId BIGINT NOT NULL,
    MetaKey VARCHAR(100) NOT NULL,
    MetaValue NVARCHAR(500) NOT NULL,

    CONSTRAINT PK_DocumentMetadata PRIMARY KEY CLUSTERED (DocumentId, MetaKey),
    CONSTRAINT FK_Metadata_Documents FOREIGN KEY (DocumentId) REFERENCES dms.Documents(DocumentId)
);
GO

CREATE NONCLUSTERED INDEX IX_DocumentMetadata_Value 
ON dms.DocumentMetadata (MetaKey, MetaValue)
INCLUDE (DocumentId);
GO


-- =========================================================================
-- 4. ERİŞİM KONTROL LİSTESİ (sec Şeması - ACL)
-- =========================================================================

CREATE TABLE sec.AccessControlLists (
    AclId BIGINT IDENTITY(1,1) NOT NULL,
    FolderId BIGINT NULL,
    DocumentId BIGINT NULL,
    PrincipalId BIGINT NOT NULL,
    PrincipalType CHAR(1) NOT NULL, -- 'U': User, 'G': Group
    CanRead BIT DEFAULT 0 NOT NULL,
    CanWrite BIT DEFAULT 0 NOT NULL,
    CanDelete BIT DEFAULT 0 NOT NULL,
    CanChangePermissions BIT DEFAULT 0 NOT NULL,

    CONSTRAINT PK_ACL PRIMARY KEY CLUSTERED (AclId),
    CONSTRAINT FK_ACL_Folders FOREIGN KEY (FolderId) REFERENCES dms.Folders(FolderId),
    CONSTRAINT FK_ACL_Documents FOREIGN KEY (DocumentId) REFERENCES dms.Documents(DocumentId),
    CONSTRAINT CHK_ACL_Target CHECK (
        (FolderId IS NOT NULL AND DocumentId IS NULL) OR 
        (FolderId IS NULL AND DocumentId IS NOT NULL)
    ),
    CONSTRAINT CHK_ACL_PrincipalType CHECK (PrincipalType IN ('U', 'G'))
);
GO

-- Mükerrer yetki tanımını önleyen Filtered Unique Index'ler
CREATE UNIQUE NONCLUSTERED INDEX UQ_ACL_Folder_Principal 
ON sec.AccessControlLists (FolderId, PrincipalId, PrincipalType)
WHERE FolderId IS NOT NULL;
GO

CREATE UNIQUE NONCLUSTERED INDEX UQ_ACL_Document_Principal 
ON sec.AccessControlLists (DocumentId, PrincipalId, PrincipalType)
WHERE DocumentId IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_ACL_SecurityCheck 
ON sec.AccessControlLists (PrincipalId, PrincipalType)
INCLUDE (FolderId, DocumentId, CanRead, CanWrite, CanDelete);
GO


-- =========================================================================
-- 5. AUDIT VE TARİHÇE LOGLARI (audit Şeması)
-- =========================================================================

CREATE TABLE audit.DocumentLogs (
    LogId BIGINT IDENTITY(1,1) NOT NULL,
    DocumentId BIGINT NOT NULL,
    VersionId BIGINT NULL,
    UserId BIGINT NOT NULL,
    ActionType VARCHAR(50) NOT NULL, -- 'CREATED', 'VIEWED', 'DOWNLOADED', 'VERSION_ADDED', 'LOCKED'
    IpAddress VARCHAR(45) NULL,
    CreatedAt DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,

    CONSTRAINT PK_DocumentLogs PRIMARY KEY CLUSTERED (LogId),
    CONSTRAINT FK_Audit_Documents FOREIGN KEY (DocumentId) REFERENCES dms.Documents(DocumentId),
    CONSTRAINT FK_Audit_Versions FOREIGN KEY (VersionId) REFERENCES dms.DocumentVersions(VersionId),
    CONSTRAINT FK_Audit_Users FOREIGN KEY (UserId) REFERENCES sec.Users(UserId)
);
GO

CREATE NONCLUSTERED INDEX IX_Audit_Timeline 
ON audit.DocumentLogs (DocumentId, CreatedAt DESC)
INCLUDE (ActionType, UserId);
GO