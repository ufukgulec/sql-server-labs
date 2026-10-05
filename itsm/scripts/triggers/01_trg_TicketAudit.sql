/* ============================================================
   TRIGGER: itsm.trg_TicketAudit
   Amaç: Tickets tablosundaki değişiklikleri (Statü, Öncelik vb.)
         otomatik olarak TicketHistory tablosuna loglar.
   ============================================================ */

CREATE TRIGGER itsm.trg_TicketAudit
ON itsm.Tickets
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Statü değiştiyse logla
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
    SELECT 
        i.TicketId,
        ISNULL(i.AssigneeId, 0), -- İşlemi yapan atanmış kişi veya sistem
        N'UPDATE',
        N'TicketStatusId',
        CAST(d.TicketStatusId AS NVARCHAR(50)),
        CAST(i.TicketStatusId AS NVARCHAR(50)),
        N'SYSTEM',
        SYSUTCDATETIME()
    FROM inserted i
    INNER JOIN deleted d ON i.TicketId = d.TicketId
    WHERE i.TicketStatusId <> d.TicketStatusId;

    -- Öncelik değiştiyse logla
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
    SELECT 
        i.TicketId,
        ISNULL(i.AssigneeId, 0),
        N'UPDATE',
        N'TicketPriorityId',
        CAST(d.TicketPriorityId AS NVARCHAR(50)),
        CAST(i.TicketPriorityId AS NVARCHAR(50)),
        N'SYSTEM',
        SYSUTCDATETIME()
    FROM inserted i
    INNER JOIN deleted d ON i.TicketId = d.TicketId
    WHERE i.TicketPriorityId <> d.TicketPriorityId;
END;
GO