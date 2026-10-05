/* ============================================================
   VIEW: itsm.vw_SlaStatusSummary
   Amaç: Bilet bazlı SLA durumunu, kalan/geçen süreleri ve 
         ihlal durumlarını izlenebilir kılmak.
   ============================================================ */

CREATE VIEW itsm.vw_SlaStatusSummary
WITH SCHEMABINDING
AS
SELECT 
    t.TicketId,
    t.TicketNumber,
    t.Subject,
    sp.Name AS SlaPolicyName,
    sp.ResponseTimeMin,
    sp.ResolutionTimeMin,
    t.CreatedAt AS TicketCreatedAt,
    t.DueAt,
    t.ResolvedAt,
    
    -- SLA Durum Analizi
    CASE 
        WHEN t.ResolvedAt IS NOT NULL AND t.ResolvedAt <= t.DueAt THEN 'RESOLVED_ON_TIME'
        WHEN t.ResolvedAt IS NOT NULL AND t.ResolvedAt > t.DueAt THEN 'RESOLVED_BREACHED'
        WHEN t.ResolvedAt IS NULL AND SYSUTCDATETIME() <= t.DueAt THEN 'IN_PROGRESS_ON_TIME'
        WHEN t.ResolvedAt IS NULL AND SYSUTCDATETIME() > t.DueAt THEN 'BREACHED'
        ELSE 'UNKNOWN'
    END AS SlaStatus

FROM itsm.Tickets t
INNER JOIN itsm.SlaPolicies sp ON t.SlaPolicyId = sp.SlaPolicyId;
GO