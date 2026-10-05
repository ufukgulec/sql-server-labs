/* ============================================================
   VIEW: itsm.vw_UserWorkloads
   Amaç: Atanan personellerin aktif iş yüklerini, açık bilet 
         sayılarını ve kritik iş yükü dağılımını özetlemek.
   ============================================================ */

CREATE VIEW itsm.vw_UserWorkloads
WITH SCHEMABINDING
AS
SELECT 
    u.UserId,
    u.Username,
    CONCAT(u.FirstName, ' ', u.LastName) AS FullName,
    u.Email,
    d.Name AS DepartmentName,
    
    -- İş Yükü Metrikleri
    COUNT(t.TicketId) AS TotalAssignedTickets,
    SUM(CASE WHEN ts.IsClosed = 0 THEN 1 ELSE 0 END) AS ActiveOpenTickets,
    SUM(CASE WHEN tp.PriorityLevel >= 8 AND ts.IsClosed = 0 THEN 1 ELSE 0 END) AS CriticalOpenTickets,
    SUM(CASE WHEN t.DueAt < SYSUTCDATETIME() AND ts.IsClosed = 0 THEN 1 ELSE 0 END) AS SlaBreachedTickets

FROM itsm.Users u
LEFT JOIN itsm.Departments d ON u.DepartmentId = d.DepartmentId
LEFT JOIN itsm.Tickets t ON u.UserId = t.AssigneeId
LEFT JOIN itsm.TicketStatuses ts ON t.TicketStatusId = ts.TicketStatusId
LEFT JOIN itsm.TicketPriorities tp ON t.TicketPriorityId = tp.TicketPriorityId
WHERE u.IsActive = 1
GROUP BY 
    u.UserId,
    u.Username,
    u.FirstName,
    u.LastName,
    u.Email,
    d.Name;
GO