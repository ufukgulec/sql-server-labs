/* ============================================================
   SQL SERVER LABS
   ITSM VERİTABANI - PRODUCTION (CANLI) ODAKLI ŞEMA
   ============================================================

   Hedef:
       Microsoft SQL Server 2022+

   Amaç:
       Production (canlı) ortam standartlarına uygun, ilişkisel ITSM veritabanı şeması.

   Tasarım Prensipleri:
       - UTC zaman damgaları
       - DATETIME2(3) veri tipi
       - İşlemsel (transactional) varlıklar için BIGINT identity anahtarlar
       - Açık PK / FK / UK / CK / DF kısıtlamaları (Constraints)
       - İyimser eşzamanlılık (optimistic concurrency) için ROWVERSION
       - Referans/ana veriler için yumuşak pasifize etme (Soft Deactivate)
       - Yıkıcı (destructive) cascade silme işlemlerinin olmaması
       - Teknik kimliklerden ayrılmış kurumsal iş belirteçleri (Business identifiers)
       - İş yükü odaklı (workload-oriented) indeksler
       - Atama grupları (Assignment groups)
       - Talep durum geçiş kuralları
       - Talep takipçileri (Watchers)
       - Talep çalışma günlükleri (Worklogs)
       - Talep ilişkileri
       - Denetim / geçmiş takibi (Audit/history tracking)

   Önemli Not:
       UpdatedAt alanı uygulama (application) tarafından yönetilir.
       Veritabanı trigger'ları bilinçli olarak kullanılmamıştır.

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


/* ============================================================
   01. DATABASE
   ============================================================ */

IF DB_ID(N'ITSM') IS NULL
BEGIN
    CREATE DATABASE ITSM;
END;
GO

USE ITSM;
GO


/* ============================================================
   02. SCHEMA
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'itsm'
)
BEGIN
    EXEC(N'CREATE SCHEMA itsm');
END;
GO


/* ============================================================
   03. TICKET NUMBER SEQUENCE
   ============================================================ */

IF OBJECT_ID(N'itsm.TicketNumberSequence', N'SO') IS NULL
BEGIN
    CREATE SEQUENCE itsm.TicketNumberSequence
        AS BIGINT
        START WITH 100000
        INCREMENT BY 1
        NO CYCLE;
END;
GO


/* ============================================================
   04. DEPARTMENTS
   ============================================================ */

CREATE TABLE itsm.Departments
(
    DepartmentId BIGINT IDENTITY(1,1) NOT NULL,

    Code        NVARCHAR(50)  NOT NULL,
    Name        NVARCHAR(150) NOT NULL,

    IsActive    BIT NOT NULL
        CONSTRAINT DF_Departments_IsActive DEFAULT (1),

    CreatedAt   DATETIME2(3) NOT NULL
        CONSTRAINT DF_Departments_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    UpdatedAt   DATETIME2(3) NULL,

    RowVersion  ROWVERSION NOT NULL,

    CONSTRAINT PK_Departments
        PRIMARY KEY CLUSTERED (DepartmentId),

    CONSTRAINT UQ_Departments_Code
        UNIQUE (Code),

    CONSTRAINT UQ_Departments_Name
        UNIQUE (Name)
);
GO


/* ============================================================
   05. USERS
   ============================================================ */

CREATE TABLE itsm.Users
(
    UserId          BIGINT IDENTITY(1,1) NOT NULL,

    Username        NVARCHAR(100) NOT NULL,
    FirstName       NVARCHAR(100) NOT NULL,
    LastName        NVARCHAR(100) NOT NULL,
    Email           NVARCHAR(320) NOT NULL,

    DepartmentId    BIGINT NULL,

    IsActive        BIT NOT NULL
        CONSTRAINT DF_Users_IsActive DEFAULT (1),

    CreatedAt       DATETIME2(3) NOT NULL
        CONSTRAINT DF_Users_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    UpdatedAt       DATETIME2(3) NULL,

    RowVersion      ROWVERSION NOT NULL,

    CONSTRAINT PK_Users
        PRIMARY KEY CLUSTERED (UserId),

    CONSTRAINT UQ_Users_Username
        UNIQUE (Username),

    CONSTRAINT UQ_Users_Email
        UNIQUE (Email),

    CONSTRAINT FK_Users_Departments
        FOREIGN KEY (DepartmentId)
        REFERENCES itsm.Departments(DepartmentId)
);
GO


/* ============================================================
   06. ROLES
   ============================================================ */

CREATE TABLE itsm.Roles
(
    RoleId      INT IDENTITY(1,1) NOT NULL,

    Code        NVARCHAR(50)  NOT NULL,
    Name        NVARCHAR(100) NOT NULL,

    IsActive    BIT NOT NULL
        CONSTRAINT DF_Roles_IsActive DEFAULT (1),

    CreatedAt   DATETIME2(3) NOT NULL
        CONSTRAINT DF_Roles_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Roles
        PRIMARY KEY CLUSTERED (RoleId),

    CONSTRAINT UQ_Roles_Code
        UNIQUE (Code),

    CONSTRAINT UQ_Roles_Name
        UNIQUE (Name)
);
GO


/* ============================================================
   07. USER ROLES
   ============================================================ */

CREATE TABLE itsm.UserRoles
(
    UserId      BIGINT NOT NULL,
    RoleId      INT    NOT NULL,

    AssignedAt  DATETIME2(3) NOT NULL
        CONSTRAINT DF_UserRoles_AssignedAt
        DEFAULT (SYSUTCDATETIME()),

    RevokedAt   DATETIME2(3) NULL,

    CONSTRAINT PK_UserRoles
        PRIMARY KEY CLUSTERED (UserId, RoleId),

    CONSTRAINT FK_UserRoles_Users
        FOREIGN KEY (UserId)
        REFERENCES itsm.Users(UserId),

    CONSTRAINT FK_UserRoles_Roles
        FOREIGN KEY (RoleId)
        REFERENCES itsm.Roles(RoleId),

    CONSTRAINT CK_UserRoles_RevokedAt
        CHECK
        (
            RevokedAt IS NULL
            OR RevokedAt >= AssignedAt
        )
);
GO


/* ============================================================
   08. TICKET TYPES
   ============================================================ */

CREATE TABLE itsm.TicketTypes
(
    TicketTypeId INT IDENTITY(1,1) NOT NULL,

    Code         NVARCHAR(50)  NOT NULL,
    Name         NVARCHAR(100) NOT NULL,

    IsActive     BIT NOT NULL
        CONSTRAINT DF_TicketTypes_IsActive DEFAULT (1),

    CreatedAt    DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketTypes_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketTypes
        PRIMARY KEY CLUSTERED (TicketTypeId),

    CONSTRAINT UQ_TicketTypes_Code
        UNIQUE (Code),

    CONSTRAINT UQ_TicketTypes_Name
        UNIQUE (Name)
);
GO


/* ============================================================
   09. TICKET STATUSES
   ============================================================ */

CREATE TABLE itsm.TicketStatuses
(
    TicketStatusId INT IDENTITY(1,1) NOT NULL,

    Code           NVARCHAR(50)  NOT NULL,
    Name           NVARCHAR(100) NOT NULL,

    IsClosed       BIT NOT NULL
        CONSTRAINT DF_TicketStatuses_IsClosed DEFAULT (0),

    SortOrder      INT NOT NULL,

    IsActive       BIT NOT NULL
        CONSTRAINT DF_TicketStatuses_IsActive DEFAULT (1),

    CreatedAt      DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketStatuses_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketStatuses
        PRIMARY KEY CLUSTERED (TicketStatusId),

    CONSTRAINT UQ_TicketStatuses_Code
        UNIQUE (Code),

    CONSTRAINT UQ_TicketStatuses_Name
        UNIQUE (Name),

    CONSTRAINT CK_TicketStatuses_SortOrder
        CHECK (SortOrder >= 0)
);
GO


/* ============================================================
   10. TICKET PRIORITIES
   ============================================================ */

CREATE TABLE itsm.TicketPriorities
(
    TicketPriorityId INT IDENTITY(1,1) NOT NULL,

    Code             NVARCHAR(50)  NOT NULL,
    Name             NVARCHAR(100) NOT NULL,

    PriorityLevel    TINYINT NOT NULL,

    IsActive         BIT NOT NULL
        CONSTRAINT DF_TicketPriorities_IsActive DEFAULT (1),

    CreatedAt        DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketPriorities_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketPriorities
        PRIMARY KEY CLUSTERED (TicketPriorityId),

    CONSTRAINT UQ_TicketPriorities_Code
        UNIQUE (Code),

    CONSTRAINT UQ_TicketPriorities_Name
        UNIQUE (Name),

    CONSTRAINT UQ_TicketPriorities_Level
        UNIQUE (PriorityLevel),

    CONSTRAINT CK_TicketPriorities_Level
        CHECK (PriorityLevel BETWEEN 1 AND 10)
);
GO


/* ============================================================
   11. CATEGORIES
   ============================================================ */

CREATE TABLE itsm.Categories
(
    CategoryId       BIGINT IDENTITY(1,1) NOT NULL,

    ParentCategoryId BIGINT NULL,

    Code             NVARCHAR(50)  NOT NULL,
    Name             NVARCHAR(150) NOT NULL,

    IsActive         BIT NOT NULL
        CONSTRAINT DF_Categories_IsActive DEFAULT (1),

    CreatedAt        DATETIME2(3) NOT NULL
        CONSTRAINT DF_Categories_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    UpdatedAt        DATETIME2(3) NULL,

    RowVersion       ROWVERSION NOT NULL,

    CONSTRAINT PK_Categories
        PRIMARY KEY CLUSTERED (CategoryId),

    CONSTRAINT UQ_Categories_Code
        UNIQUE (Code),

    CONSTRAINT FK_Categories_Parent
        FOREIGN KEY (ParentCategoryId)
        REFERENCES itsm.Categories(CategoryId),

    CONSTRAINT CK_Categories_NotSelfParent
        CHECK
        (
            ParentCategoryId IS NULL
            OR ParentCategoryId <> CategoryId
        )
);
GO


/* ============================================================
   12. SERVICES
   ============================================================ */

CREATE TABLE itsm.Services
(
    ServiceId    BIGINT IDENTITY(1,1) NOT NULL,

    Code         NVARCHAR(50)  NOT NULL,
    Name         NVARCHAR(150) NOT NULL,

    OwnerUserId  BIGINT NULL,

    IsActive     BIT NOT NULL
        CONSTRAINT DF_Services_IsActive DEFAULT (1),

    CreatedAt    DATETIME2(3) NOT NULL
        CONSTRAINT DF_Services_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    UpdatedAt    DATETIME2(3) NULL,

    RowVersion   ROWVERSION NOT NULL,

    CONSTRAINT PK_Services
        PRIMARY KEY CLUSTERED (ServiceId),

    CONSTRAINT UQ_Services_Code
        UNIQUE (Code),

    CONSTRAINT UQ_Services_Name
        UNIQUE (Name),

    CONSTRAINT FK_Services_OwnerUser
        FOREIGN KEY (OwnerUserId)
        REFERENCES itsm.Users(UserId)
);
GO


/* ============================================================
   13. SLA POLICIES
   ============================================================ */

CREATE TABLE itsm.SlaPolicies
(
    SlaPolicyId       INT IDENTITY(1,1) NOT NULL,

    Code              NVARCHAR(50)  NOT NULL,
    Name              NVARCHAR(150) NOT NULL,

    ResponseTimeMin   INT NOT NULL,
    ResolutionTimeMin INT NOT NULL,

    IsActive          BIT NOT NULL
        CONSTRAINT DF_SlaPolicies_IsActive DEFAULT (1),

    CreatedAt         DATETIME2(3) NOT NULL
        CONSTRAINT DF_SlaPolicies_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_SlaPolicies
        PRIMARY KEY CLUSTERED (SlaPolicyId),

    CONSTRAINT UQ_SlaPolicies_Code
        UNIQUE (Code),

    CONSTRAINT UQ_SlaPolicies_Name
        UNIQUE (Name),

    CONSTRAINT CK_SlaPolicies_ResponseTime
        CHECK (ResponseTimeMin > 0),

    CONSTRAINT CK_SlaPolicies_ResolutionTime
        CHECK (ResolutionTimeMin > 0)
);
GO


/* ============================================================
   14. ASSIGNMENT GROUPS
   ============================================================ */

CREATE TABLE itsm.AssignmentGroups
(
    AssignmentGroupId BIGINT IDENTITY(1,1) NOT NULL,

    Code              NVARCHAR(50)  NOT NULL,
    Name              NVARCHAR(150) NOT NULL,

    ManagerUserId     BIGINT NULL,

    IsActive          BIT NOT NULL
        CONSTRAINT DF_AssignmentGroups_IsActive DEFAULT (1),

    CreatedAt         DATETIME2(3) NOT NULL
        CONSTRAINT DF_AssignmentGroups_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    UpdatedAt         DATETIME2(3) NULL,

    RowVersion        ROWVERSION NOT NULL,

    CONSTRAINT PK_AssignmentGroups
        PRIMARY KEY CLUSTERED (AssignmentGroupId),

    CONSTRAINT UQ_AssignmentGroups_Code
        UNIQUE (Code),

    CONSTRAINT UQ_AssignmentGroups_Name
        UNIQUE (Name),

    CONSTRAINT FK_AssignmentGroups_Manager
        FOREIGN KEY (ManagerUserId)
        REFERENCES itsm.Users(UserId)
);
GO


/* ============================================================
   15. ASSIGNMENT GROUP MEMBERS
   ============================================================ */

CREATE TABLE itsm.AssignmentGroupMembers
(
    AssignmentGroupId BIGINT NOT NULL,
    UserId            BIGINT NOT NULL,

    JoinedAt          DATETIME2(3) NOT NULL
        CONSTRAINT DF_AssignmentGroupMembers_JoinedAt
        DEFAULT (SYSUTCDATETIME()),

    LeftAt            DATETIME2(3) NULL,

    CONSTRAINT PK_AssignmentGroupMembers
        PRIMARY KEY CLUSTERED
        (
            AssignmentGroupId,
            UserId
        ),

    CONSTRAINT FK_AssignmentGroupMembers_Groups
        FOREIGN KEY (AssignmentGroupId)
        REFERENCES itsm.AssignmentGroups(AssignmentGroupId),

    CONSTRAINT FK_AssignmentGroupMembers_Users
        FOREIGN KEY (UserId)
        REFERENCES itsm.Users(UserId),

    CONSTRAINT CK_AssignmentGroupMembers_LeftAt
        CHECK
        (
            LeftAt IS NULL
            OR LeftAt >= JoinedAt
        )
);
GO


/* ============================================================
   16. TICKETS
   ============================================================ */

CREATE TABLE itsm.Tickets
(
    TicketId         BIGINT IDENTITY(1,1) NOT NULL,

    TicketNumber     BIGINT NOT NULL
        CONSTRAINT DF_Tickets_TicketNumber
        DEFAULT (NEXT VALUE FOR itsm.TicketNumberSequence),

    Subject          NVARCHAR(300) NOT NULL,
    Description      NVARCHAR(MAX) NULL,

    TicketTypeId     INT NOT NULL,
    TicketStatusId   INT NOT NULL,
    TicketPriorityId INT NOT NULL,

    CategoryId       BIGINT NULL,
    ServiceId        BIGINT NULL,
    DepartmentId     BIGINT NULL,

    RequesterId      BIGINT NOT NULL,

    AssignmentGroupId BIGINT NULL,
    AssigneeId        BIGINT NULL,

    SlaPolicyId      INT NULL,

    DueAt            DATETIME2(3) NULL,
    FirstResponseAt  DATETIME2(3) NULL,
    ResolvedAt       DATETIME2(3) NULL,
    ClosedAt         DATETIME2(3) NULL,

    CreatedAt        DATETIME2(3) NOT NULL
        CONSTRAINT DF_Tickets_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    UpdatedAt        DATETIME2(3) NULL,

    RowVersion       ROWVERSION NOT NULL,

    CONSTRAINT PK_Tickets
        PRIMARY KEY CLUSTERED (TicketId),

    CONSTRAINT UQ_Tickets_TicketNumber
        UNIQUE (TicketNumber),

    CONSTRAINT FK_Tickets_TicketTypes
        FOREIGN KEY (TicketTypeId)
        REFERENCES itsm.TicketTypes(TicketTypeId),

    CONSTRAINT FK_Tickets_TicketStatuses
        FOREIGN KEY (TicketStatusId)
        REFERENCES itsm.TicketStatuses(TicketStatusId),

    CONSTRAINT FK_Tickets_TicketPriorities
        FOREIGN KEY (TicketPriorityId)
        REFERENCES itsm.TicketPriorities(TicketPriorityId),

    CONSTRAINT FK_Tickets_Categories
        FOREIGN KEY (CategoryId)
        REFERENCES itsm.Categories(CategoryId),

    CONSTRAINT FK_Tickets_Services
        FOREIGN KEY (ServiceId)
        REFERENCES itsm.Services(ServiceId),

    CONSTRAINT FK_Tickets_Departments
        FOREIGN KEY (DepartmentId)
        REFERENCES itsm.Departments(DepartmentId),

    CONSTRAINT FK_Tickets_Requester
        FOREIGN KEY (RequesterId)
        REFERENCES itsm.Users(UserId),

    CONSTRAINT FK_Tickets_AssignmentGroup
        FOREIGN KEY (AssignmentGroupId)
        REFERENCES itsm.AssignmentGroups(AssignmentGroupId),

    CONSTRAINT FK_Tickets_Assignee
        FOREIGN KEY (AssigneeId)
        REFERENCES itsm.Users(UserId),

    CONSTRAINT FK_Tickets_SlaPolicies
        FOREIGN KEY (SlaPolicyId)
        REFERENCES itsm.SlaPolicies(SlaPolicyId),

    CONSTRAINT CK_Tickets_FirstResponseAt
        CHECK
        (
            FirstResponseAt IS NULL
            OR FirstResponseAt >= CreatedAt
        ),

    CONSTRAINT CK_Tickets_ResolvedAt
        CHECK
        (
            ResolvedAt IS NULL
            OR ResolvedAt >= CreatedAt
        ),

    CONSTRAINT CK_Tickets_ClosedAt
        CHECK
        (
            ClosedAt IS NULL
            OR ClosedAt >= CreatedAt
        ),

    CONSTRAINT CK_Tickets_ClosedRequiresResolved
        CHECK
        (
            ClosedAt IS NULL
            OR ResolvedAt IS NOT NULL
        ),

    CONSTRAINT CK_Tickets_ClosedAfterResolved
        CHECK
        (
            ClosedAt IS NULL
            OR ResolvedAt IS NULL
            OR ClosedAt >= ResolvedAt
        ),

    CONSTRAINT CK_Tickets_AssigneeRequiresGroup
        CHECK
        (
            AssigneeId IS NULL
            OR AssignmentGroupId IS NOT NULL
        )
);
GO


/* ============================================================
   17. TICKET STATUS TRANSITIONS
   ============================================================ */

CREATE TABLE itsm.TicketStatusTransitions
(
    TicketStatusTransitionId BIGINT IDENTITY(1,1) NOT NULL,

    FromStatusId             INT NOT NULL,
    ToStatusId               INT NOT NULL,

    IsActive                 BIT NOT NULL
        CONSTRAINT DF_TicketStatusTransitions_IsActive DEFAULT (1),

    CreatedAt                DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketStatusTransitions_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketStatusTransitions
        PRIMARY KEY CLUSTERED
        (
            TicketStatusTransitionId
        ),

    CONSTRAINT UQ_TicketStatusTransitions
        UNIQUE
        (
            FromStatusId,
            ToStatusId
        ),

    CONSTRAINT FK_TicketStatusTransitions_From
        FOREIGN KEY (FromStatusId)
        REFERENCES itsm.TicketStatuses(TicketStatusId),

    CONSTRAINT FK_TicketStatusTransitions_To
        FOREIGN KEY (ToStatusId)
        REFERENCES itsm.TicketStatuses(TicketStatusId),

    CONSTRAINT CK_TicketStatusTransitions_NotSame
        CHECK
        (
            FromStatusId <> ToStatusId
        )
);
GO


/* ============================================================
   18. TICKET COMMENTS
   ============================================================ */

CREATE TABLE itsm.TicketComments
(
    TicketCommentId BIGINT IDENTITY(1,1) NOT NULL,

    TicketId        BIGINT NOT NULL,
    UserId          BIGINT NOT NULL,

    Comment         NVARCHAR(MAX) NOT NULL,

    IsInternal      BIT NOT NULL
        CONSTRAINT DF_TicketComments_IsInternal DEFAULT (0),

    CreatedAt       DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketComments_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    UpdatedAt       DATETIME2(3) NULL,

    RowVersion      ROWVERSION NOT NULL,

    CONSTRAINT PK_TicketComments
        PRIMARY KEY CLUSTERED (TicketCommentId),

    CONSTRAINT FK_TicketComments_Tickets
        FOREIGN KEY (TicketId)
        REFERENCES itsm.Tickets(TicketId),

    CONSTRAINT FK_TicketComments_Users
        FOREIGN KEY (UserId)
        REFERENCES itsm.Users(UserId)
);
GO


/* ============================================================
   19. TICKET HISTORY / AUDIT
   ============================================================ */

CREATE TABLE itsm.TicketHistory
(
    TicketHistoryId BIGINT IDENTITY(1,1) NOT NULL,

    TicketId        BIGINT NOT NULL,
    UserId          BIGINT NULL,

    ActionType      NVARCHAR(50) NOT NULL,

    FieldName       NVARCHAR(100) NULL,

    OldValue        NVARCHAR(MAX) NULL,
    NewValue        NVARCHAR(MAX) NULL,

    OldDisplayValue NVARCHAR(500) NULL,
    NewDisplayValue NVARCHAR(500) NULL,

    Source          NVARCHAR(30) NOT NULL
        CONSTRAINT DF_TicketHistory_Source DEFAULT (N'APPLICATION'),

    CorrelationId   UNIQUEIDENTIFIER NULL,

    CreatedAt       DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketHistory_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketHistory
        PRIMARY KEY CLUSTERED (TicketHistoryId),

    CONSTRAINT FK_TicketHistory_Tickets
        FOREIGN KEY (TicketId)
        REFERENCES itsm.Tickets(TicketId),

    CONSTRAINT FK_TicketHistory_Users
        FOREIGN KEY (UserId)
        REFERENCES itsm.Users(UserId),

    CONSTRAINT CK_TicketHistory_Source
        CHECK
        (
            Source IN
            (
                N'APPLICATION',
                N'API',
                N'SYSTEM',
                N'IMPORT',
                N'INTEGRATION',
                N'JOB'
            )
        )
);
GO


/* ============================================================
   20. TICKET ATTACHMENTS
   ============================================================ */

CREATE TABLE itsm.TicketAttachments
(
    TicketAttachmentId BIGINT IDENTITY(1,1) NOT NULL,

    TicketId           BIGINT NOT NULL,
    UploadedByUserId   BIGINT NOT NULL,

    FileName           NVARCHAR(255) NOT NULL,
    ContentType        NVARCHAR(255) NULL,
    FileSizeBytes      BIGINT NOT NULL,

    StorageProvider    NVARCHAR(50) NOT NULL,
    StorageKey         NVARCHAR(900) NOT NULL,
    
    StorageKeyHash AS CONVERT(BINARY(32), HASHBYTES('SHA2_256', StorageKey)) PERSISTED NOT NULL,

    CreatedAt          DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketAttachments_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketAttachments
        PRIMARY KEY CLUSTERED (TicketAttachmentId),

    CONSTRAINT UQ_TicketAttachments_Storage
        UNIQUE
        (
            StorageProvider,
            StorageKeyHash
        ),

    CONSTRAINT FK_TicketAttachments_Tickets
        FOREIGN KEY (TicketId)
        REFERENCES itsm.Tickets(TicketId),

    CONSTRAINT FK_TicketAttachments_Users
        FOREIGN KEY (UploadedByUserId)
        REFERENCES itsm.Users(UserId),

    CONSTRAINT CK_TicketAttachments_FileSize
        CHECK (FileSizeBytes > 0)
);
GO


/* ============================================================
   21. TAGS
   ============================================================ */

CREATE TABLE itsm.Tags
(
    TagId       INT IDENTITY(1,1) NOT NULL,

    Name        NVARCHAR(100) NOT NULL,

    IsActive    BIT NOT NULL
        CONSTRAINT DF_Tags_IsActive DEFAULT (1),

    CreatedAt   DATETIME2(3) NOT NULL
        CONSTRAINT DF_Tags_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Tags
        PRIMARY KEY CLUSTERED (TagId),

    CONSTRAINT UQ_Tags_Name
        UNIQUE (Name)
);
GO


/* ============================================================
   22. TICKET TAGS
   ============================================================ */

CREATE TABLE itsm.TicketTags
(
    TicketId BIGINT NOT NULL,
    TagId    INT NOT NULL,

    CreatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketTags_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketTags
        PRIMARY KEY CLUSTERED (TicketId, TagId),

    CONSTRAINT FK_TicketTags_Tickets
        FOREIGN KEY (TicketId)
        REFERENCES itsm.Tickets(TicketId),

    CONSTRAINT FK_TicketTags_Tags
        FOREIGN KEY (TagId)
        REFERENCES itsm.Tags(TagId)
);
GO


/* ============================================================
   23. TICKET WATCHERS
   ============================================================ */

CREATE TABLE itsm.TicketWatchers
(
    TicketId  BIGINT NOT NULL,
    UserId    BIGINT NOT NULL,

    CreatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketWatchers_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketWatchers
        PRIMARY KEY CLUSTERED (TicketId, UserId),

    CONSTRAINT FK_TicketWatchers_Tickets
        FOREIGN KEY (TicketId)
        REFERENCES itsm.Tickets(TicketId),

    CONSTRAINT FK_TicketWatchers_Users
        FOREIGN KEY (UserId)
        REFERENCES itsm.Users(UserId)
);
GO


/* ============================================================
   24. TICKET WORKLOGS
   ============================================================ */

CREATE TABLE itsm.TicketWorkLogs
(
    TicketWorkLogId BIGINT IDENTITY(1,1) NOT NULL,

    TicketId        BIGINT NOT NULL,
    UserId          BIGINT NOT NULL,

    StartedAt       DATETIME2(3) NOT NULL,
    EndedAt         DATETIME2(3) NOT NULL,

    DurationMinutes INT NOT NULL,

    Description     NVARCHAR(2000) NULL,

    IsBillable      BIT NOT NULL
        CONSTRAINT DF_TicketWorkLogs_IsBillable DEFAULT (0),

    CreatedAt       DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketWorkLogs_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketWorkLogs
        PRIMARY KEY CLUSTERED (TicketWorkLogId),

    CONSTRAINT FK_TicketWorkLogs_Tickets
        FOREIGN KEY (TicketId)
        REFERENCES itsm.Tickets(TicketId),

    CONSTRAINT FK_TicketWorkLogs_Users
        FOREIGN KEY (UserId)
        REFERENCES itsm.Users(UserId),

    CONSTRAINT CK_TicketWorkLogs_TimeRange
        CHECK
        (
            EndedAt > StartedAt
        ),

    CONSTRAINT CK_TicketWorkLogs_Duration
        CHECK
        (
            DurationMinutes > 0
        )
);
GO


/* ============================================================
   25. TICKET LINK TYPES
   ============================================================ */

CREATE TABLE itsm.TicketLinkTypes
(
    TicketLinkTypeId INT IDENTITY(1,1) NOT NULL,

    Code             NVARCHAR(50)  NOT NULL,
    Name             NVARCHAR(100) NOT NULL,

    IsActive         BIT NOT NULL
        CONSTRAINT DF_TicketLinkTypes_IsActive DEFAULT (1),

    CreatedAt        DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketLinkTypes_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketLinkTypes
        PRIMARY KEY CLUSTERED (TicketLinkTypeId),

    CONSTRAINT UQ_TicketLinkTypes_Code
        UNIQUE (Code),

    CONSTRAINT UQ_TicketLinkTypes_Name
        UNIQUE (Name)
);
GO


/* ============================================================
   26. TICKET LINKS
   ============================================================ */

CREATE TABLE itsm.TicketLinks
(
    TicketLinkId     BIGINT IDENTITY(1,1) NOT NULL,

    TicketId         BIGINT NOT NULL,
    RelatedTicketId  BIGINT NOT NULL,
    TicketLinkTypeId INT NOT NULL,

    CreatedAt        DATETIME2(3) NOT NULL
        CONSTRAINT DF_TicketLinks_CreatedAt
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_TicketLinks
        PRIMARY KEY CLUSTERED (TicketLinkId),

    CONSTRAINT UQ_TicketLinks
        UNIQUE
        (
            TicketId,
            RelatedTicketId,
            TicketLinkTypeId
        ),

    CONSTRAINT FK_TicketLinks_Ticket
        FOREIGN KEY (TicketId)
        REFERENCES itsm.Tickets(TicketId),

    CONSTRAINT FK_TicketLinks_RelatedTicket
        FOREIGN KEY (RelatedTicketId)
        REFERENCES itsm.Tickets(TicketId),

    CONSTRAINT FK_TicketLinks_LinkType
        FOREIGN KEY (TicketLinkTypeId)
        REFERENCES itsm.TicketLinkTypes(TicketLinkTypeId),

    CONSTRAINT CK_TicketLinks_NotSelf
        CHECK
        (
            TicketId <> RelatedTicketId
        )
);
GO


/* ============================================================
   INDEXES
   ============================================================ */


/* ============================================================
   USERS
   ============================================================ */

CREATE INDEX IX_Users_DepartmentId
ON itsm.Users
(
    DepartmentId
)
INCLUDE
(
    Username,
    FirstName,
    LastName,
    Email,
    IsActive
)
WHERE DepartmentId IS NOT NULL;
GO


/* ============================================================
   USER ROLES
   ============================================================ */

CREATE INDEX IX_UserRoles_RoleId_UserId
ON itsm.UserRoles
(
    RoleId,
    UserId
)
INCLUDE
(
    AssignedAt,
    RevokedAt
);
GO


/* ============================================================
   CATEGORIES
   ============================================================ */

CREATE INDEX IX_Categories_ParentCategoryId
ON itsm.Categories
(
    ParentCategoryId
)
INCLUDE
(
    Code,
    Name,
    IsActive
)
WHERE ParentCategoryId IS NOT NULL;
GO


/* ============================================================
   SERVICES
   ============================================================ */

CREATE INDEX IX_Services_OwnerUserId
ON itsm.Services
(
    OwnerUserId
)
WHERE OwnerUserId IS NOT NULL;
GO


/* ============================================================
   ASSIGNMENT GROUPS
   ============================================================ */

CREATE INDEX IX_AssignmentGroups_ManagerUserId
ON itsm.AssignmentGroups
(
    ManagerUserId
)
WHERE ManagerUserId IS NOT NULL;
GO


/* ============================================================
   ASSIGNMENT GROUP MEMBERS
   ============================================================ */

CREATE INDEX IX_AssignmentGroupMembers_UserId_GroupId
ON itsm.AssignmentGroupMembers
(
    UserId,
    AssignmentGroupId
)
INCLUDE
(
    JoinedAt,
    LeftAt
);
GO


/* ============================================================
   TICKET STATUS TRANSITIONS
   ============================================================ */

CREATE INDEX IX_TicketStatusTransitions_FromStatusId
ON itsm.TicketStatusTransitions
(
    FromStatusId,
    IsActive
)
INCLUDE
(
    ToStatusId
);
GO


CREATE INDEX IX_TicketStatusTransitions_ToStatusId
ON itsm.TicketStatusTransitions
(
    ToStatusId,
    IsActive
)
INCLUDE
(
    FromStatusId
);
GO


/* ============================================================
   TICKETS - REQUESTER
   ============================================================ */

CREATE INDEX IX_Tickets_RequesterId_CreatedAt
ON itsm.Tickets
(
    RequesterId,
    CreatedAt DESC
)
INCLUDE
(
    TicketNumber,
    Subject,
    TicketStatusId,
    TicketPriorityId,
    AssigneeId
);
GO


/* ============================================================
   TICKETS - ASSIGNEE
   ============================================================ */

CREATE INDEX IX_Tickets_AssigneeId_StatusId_CreatedAt
ON itsm.Tickets
(
    AssigneeId,
    TicketStatusId,
    CreatedAt DESC
)
INCLUDE
(
    TicketNumber,
    Subject,
    TicketPriorityId,
    DueAt,
    AssignmentGroupId
)
WHERE AssigneeId IS NOT NULL;
GO


/* ============================================================
   TICKETS - ASSIGNMENT GROUP
   ============================================================ */

CREATE INDEX IX_Tickets_AssignmentGroupId_StatusId_CreatedAt
ON itsm.Tickets
(
    AssignmentGroupId,
    TicketStatusId,
    CreatedAt DESC
)
INCLUDE
(
    TicketNumber,
    Subject,
    TicketPriorityId,
    AssigneeId,
    DueAt
)
WHERE AssignmentGroupId IS NOT NULL;
GO


/* ============================================================
   TICKETS - DEPARTMENT
   ============================================================ */

CREATE INDEX IX_Tickets_DepartmentId_StatusId_CreatedAt
ON itsm.Tickets
(
    DepartmentId,
    TicketStatusId,
    CreatedAt DESC
)
INCLUDE
(
    TicketNumber,
    Subject,
    TicketPriorityId,
    AssigneeId
)
WHERE DepartmentId IS NOT NULL;
GO


/* ============================================================
   TICKETS - STATUS
   ============================================================ */

CREATE INDEX IX_Tickets_StatusId_CreatedAt
ON itsm.Tickets
(
    TicketStatusId,
    CreatedAt DESC
)
INCLUDE
(
    TicketNumber,
    Subject,
    TicketPriorityId,
    AssigneeId,
    RequesterId,
    DueAt
);
GO


/* ============================================================
   TICKETS - SLA / DUE DATE
   ============================================================ */

CREATE INDEX IX_Tickets_DueAt
ON itsm.Tickets
(
    DueAt
)
INCLUDE
(
    TicketNumber,
    TicketStatusId,
    TicketPriorityId,
    AssigneeId,
    AssignmentGroupId,
    ServiceId
)
WHERE DueAt IS NOT NULL;
GO


/* ============================================================
   TICKETS - CATEGORY
   ============================================================ */

CREATE INDEX IX_Tickets_CategoryId_CreatedAt
ON itsm.Tickets
(
    CategoryId,
    CreatedAt DESC
)
INCLUDE
(
    TicketNumber,
    TicketStatusId,
    TicketPriorityId,
    AssigneeId
)
WHERE CategoryId IS NOT NULL;
GO


/* ============================================================
   TICKETS - SERVICE
   ============================================================ */

CREATE INDEX IX_Tickets_ServiceId_StatusId
ON itsm.Tickets
(
    ServiceId,
    TicketStatusId
)
INCLUDE
(
    TicketNumber,
    CreatedAt,
    AssigneeId,
    AssignmentGroupId,
    TicketPriorityId
)
WHERE ServiceId IS NOT NULL;
GO


/* ============================================================
   TICKET COMMENTS
   ============================================================ */

CREATE INDEX IX_TicketComments_TicketId_CreatedAt
ON itsm.TicketComments
(
    TicketId,
    CreatedAt DESC
)
INCLUDE
(
    UserId,
    IsInternal
);
GO


/* ============================================================
   TICKET HISTORY
   ============================================================ */

CREATE INDEX IX_TicketHistory_TicketId_CreatedAt
ON itsm.TicketHistory
(
    TicketId,
    CreatedAt DESC
)
INCLUDE
(
    UserId,
    ActionType,
    FieldName,
    Source,
    CorrelationId
);
GO


/* ============================================================
   TICKET ATTACHMENTS
   ============================================================ */

CREATE INDEX IX_TicketAttachments_TicketId_CreatedAt
ON itsm.TicketAttachments
(
    TicketId,
    CreatedAt DESC
)
INCLUDE
(
    FileName,
    ContentType,
    FileSizeBytes,
    UploadedByUserId,
    StorageProvider
);
GO


/* ============================================================
   TICKET TAGS
   ============================================================ */

CREATE INDEX IX_TicketTags_TagId_TicketId
ON itsm.TicketTags
(
    TagId,
    TicketId
);
GO


/* ============================================================
   TICKET WATCHERS
   ============================================================ */

CREATE INDEX IX_TicketWatchers_UserId_TicketId
ON itsm.TicketWatchers
(
    UserId,
    TicketId
);
GO


/* ============================================================
   TICKET WORKLOGS
   ============================================================ */

CREATE INDEX IX_TicketWorkLogs_TicketId_StartedAt
ON itsm.TicketWorkLogs
(
    TicketId,
    StartedAt DESC
)
INCLUDE
(
    UserId,
    EndedAt,
    DurationMinutes,
    IsBillable
);
GO


CREATE INDEX IX_TicketWorkLogs_UserId_StartedAt
ON itsm.TicketWorkLogs
(
    UserId,
    StartedAt DESC
)
INCLUDE
(
    TicketId,
    EndedAt,
    DurationMinutes,
    IsBillable
);
GO


/* ============================================================
   TICKET LINKS
   ============================================================ */

CREATE INDEX IX_TicketLinks_TicketId
ON itsm.TicketLinks
(
    TicketId
)
INCLUDE
(
    RelatedTicketId,
    TicketLinkTypeId,
    CreatedAt
);
GO


CREATE INDEX IX_TicketLinks_RelatedTicketId
ON itsm.TicketLinks
(
    RelatedTicketId
)
INCLUDE
(
    TicketId,
    TicketLinkTypeId,
    CreatedAt
);
GO


/* ============================================================
   COMPLETED
   ============================================================ */

PRINT 'ITSM database schema created successfully.';
GO
