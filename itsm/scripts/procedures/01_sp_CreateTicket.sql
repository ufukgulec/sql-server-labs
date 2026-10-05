/* ============================================================
   PROCEDURE: itsm.sp_CreateTicket
   Amaç: Yeni bir ITSM bileti oluşturur, SLA bitiş tarihini hesaplar 
         ve transaction güvenliği sağlar.
   ============================================================ */

CREATE PROCEDURE itsm.sp_CreateTicket
    @Subject          NVARCHAR(300),
    @Description      NVARCHAR(MAX) = NULL,
    @TicketTypeId     INT,
    @TicketPriorityId INT,
    @RequesterId      BIGINT,
    @CategoryId       BIGINT = NULL,
    @ServiceId        BIGINT = NULL,
    @DepartmentId     BIGINT = NULL,
    @AssignmentGroupId BIGINT = NULL,
    @SlaPolicyId      INT = NULL,
    @NewTicketId      BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Eğer SLA Politikası dışarıdan verilmediyse, önceliğe göre varsayılan bir politika atanabilir
        -- (Bu örnekte parametre olarak geldiği varsayılıyor veya NULL bırakılıyor)
        DECLARE @CalculatedDueAt DATETIME2(3) = NULL;

        IF @SlaPolicyId IS NOT NULL
        BEGIN
            DECLARE @ResolutionMinutes INT;
            SELECT @ResolutionMinutes = ResolutionTimeMin 
            FROM itsm.SlaPolicies 
            WHERE SlaPolicyId = @SlaPolicyId AND IsActive = 1;

            IF @ResolutionMinutes IS NOT NULL
            BEGIN
                -- Daha önce yazdığımız fonksiyonu kullanarak DueAt hesapla
                SET @CalculatedDueAt = itsm.fn_CalculateBusinessDueDate(SYSUTCDATETIME(), @ResolutionMinutes);
            END
        END

        -- 2. Varsayılan Başlangıç Statüsü (Örn: 'NEW' statüsünün ID'sini bulalım)
        DECLARE @DefaultStatusId INT;
        SELECT TOP 1 @DefaultStatusId = TicketStatusId 
        FROM itsm.TicketStatuses 
        WHERE Code = N'NEW' AND IsActive = 1;

        IF @DefaultStatusId IS NULL
        BEGIN
            RAISERROR('Sistemde aktif "NEW" (Yeni) statüsü bulunamadı.', 16, 1);
        END

        -- 3. Bileti Kaydet
        INSERT INTO itsm.Tickets
        (
            Subject,
            Description,
            TicketTypeId,
            TicketStatusId,
            TicketPriorityId,
            CategoryId,
            ServiceId,
            DepartmentId,
            RequesterId,
            AssignmentGroupId,
            SlaPolicyId,
            DueAt,
            CreatedAt
        )
        VALUES
        (
            @Subject,
            @Description,
            @TicketTypeId,
            @DefaultStatusId,
            @TicketPriorityId,
            @CategoryId,
            @ServiceId,
            @DepartmentId,
            @RequesterId,
            @AssignmentGroupId,
            @SlaPolicyId,
            @CalculatedDueAt,
            SYSUTCDATETIME()
        );

        SET @NewTicketId = SCOPE_IDENTITY();

        -- 4. Audit / Tarihçe Kaydı At
        INSERT INTO itsm.TicketHistory
        (
            TicketId,
            UserId,
            ActionType,
            FieldName,
            NewValue,
            Source,
            CreatedAt
        )
        VALUES
        (
            @NewTicketId,
            @RequesterId,
            N'CREATE',
            N'TicketId',
            CAST(@NewTicketId AS NVARCHAR(50)),
            N'APPLICATION',
            SYSUTCDATETIME()
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO