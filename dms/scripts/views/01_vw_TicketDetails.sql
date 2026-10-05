/* ============================================================
   VIEW: itsm.vw_TicketDetails
   Amaç: Biletlerin temel, statü, öncelik, kategori, servis ve 
         atama detaylarını tek sorguda birleştiren ana görünüm.
   ============================================================ */

CREATE VIEW itsm.vw_TicketDetails
WITH SCHEMABINDING
AS
SELECT 
    t.TicketId,
    t.TicketNumber,
    t.Subject,
    t.Description,
    
    -- Tür, Statü, Öncelik
    tt.Code AS TicketTypeCode,
    tt.Name AS TicketTypeName,
    ts.Code AS TicketStatusCode,
    ts.Name AS TicketStatusName,
    ts.IsClosed AS IsTicketClosed,
    ts.SortOrder AS StatusSortOrder,
    tp.Code AS TicketPriorityCode,
    tp.Name AS TicketPriorityName,
    tp.PriorityLevel,

    -- Kategori, Servis, Departman
    c.Code AS CategoryCode,
    c.Name AS CategoryName,
    s.Code AS ServiceCode,
    s.Name AS ServiceName,
    d.Code AS DepartmentCode,
    d.Name AS DepartmentName,

    -- Aktörler (Talep Eden, Atanan Grup, Atanan Personel)
    req.Username AS RequesterUsername,
    CONCAT(req.FirstName, ' ', req.LastName) AS RequesterFullName,
    req.Email AS RequesterEmail,

    ag.Code AS AssignmentGroupCode,
    ag.Name AS AssignmentGroupName,

    assignee.Username AS AssigneeUsername,
    CONCAT(assignee.FirstName, ' ', assignee.LastName) AS AssigneeFullName,

    -- SLA ve Tarihler
    sp.Code AS SlaPolicyCode,
    sp.Name AS SlaPolicyName,
    t.DueAt,
    t.FirstResponseAt,
    t.ResolvedAt,
    t.ClosedAt,
    t.CreatedAt,
    t.UpdatedAt,
    t.RowVersion

FROM itsm.Tickets t
INNER JOIN itsm.TicketTypes tt ON t.TicketTypeId = tt.TicketTypeId
INNER JOIN itsm.TicketStatuses ts ON t.TicketStatusId = ts.TicketStatusId
INNER JOIN itsm.TicketPriorities tp ON t.TicketPriorityId = tp.TicketPriorityId
LEFT JOIN itsm.Categories c ON t.CategoryId = c.CategoryId
LEFT JOIN itsm.Services s ON t.ServiceId = s.ServiceId
LEFT JOIN itsm.Departments d ON t.DepartmentId = d.DepartmentId
INNER JOIN itsm.Users req ON t.RequesterId = req.UserId
LEFT JOIN itsm.AssignmentGroups ag ON t.AssignmentGroupId = ag.AssignmentGroupId
LEFT JOIN itsm.Users assignee ON t.AssigneeId = assignee.UserId
LEFT JOIN itsm.SlaPolicies sp ON t.SlaPolicyId = sp.SlaPolicyId;
GO