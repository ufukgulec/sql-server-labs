/* ============================================================
   PROCEDURE: itsm.sp_AssignTicket
   Amaç: Bir bileti atama grubuna ve personele güvenli şekilde 
         tayin eder ve geçmişe loglar.
   ============================================================ */

CREATE PROCEDURE itsm.sp_AssignTicket
    @TicketId          BIGINT,
    @AssignmentGroupId BIGINT,
    @AssigneeId        BIGINT,
    @UpdatedByUserId   BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Kullanıcının o gruba üyeliğini kontrol et (Fonksiyon kullanarak)
        IF itsm.fn_CheckUserGroupMembership(@AssigneeId, @AssignmentGroupId) = 0
        BEGIN
            RAISERROR('Atanmak istenen personel, belirtilen Atama Grubuun aktif bir üyesi değildir.', 16, 1);
        END

        -- 2. Eski değerleri audit için yakala
        DECLARE @OldAssigneeId BIGINT;
        DECLARE @OldGroupId BIGINT;

        SELECT 
            @OldAssigneeId = AssigneeId, 
            @OldGroupId = AssignmentGroupId 
        FROM itsm.Tickets 
        WHERE TicketId = @TicketId;

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Belirtilen bilet bulunamadı.', 16, 1);
        END

        -- 3. Bileti Güncelle
        UPDATE itsm.Tickets
        SET AssignmentGroupId = @AssignmentGroupId,
            AssigneeId = @AssigneeId,
            UpdatedAt = SYSUTCDATETIME()
        WHERE TicketId = @TicketId;

        -- 4. Tarihçe / Audit Kaydı Ekle
        INSERT INTO itsm.TicketHistory
        (
            TicketId,
            UserId,
            ActionType,
            FieldName,
            OldValue,
            NewValue,
            Source,
            CreatedAt
        )
        VALUES
        (
            @TicketId,
            @UpdatedByUserId,
            N'ASSIGN',
            N'AssigneeId',
            CAST(ISNULL(@OldAssigneeId, 0) AS NVARCHAR(50)),
            CAST(@AssigneeId AS NVARCHAR(50)),
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