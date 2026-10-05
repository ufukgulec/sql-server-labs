/* ============================================================
   FUNCTION: itsm.fn_GetTicketAgeInMinutes
   Amaç: Biletin yaşı veya işlem süresini dakika cinsinden döndürür.
   ============================================================ */

CREATE FUNCTION itsm.fn_GetTicketAgeInMinutes
(
    @CreatedAt DATETIME2(3),
    @ResolvedAt DATETIME2(3)
)
RETURNS INT
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @TargetEnd DATETIME2(3);
    DECLARE @Minutes INT;

    -- Eğer bilet çözüldüyse çözüm anına kadar, çözülmediyse şu ana kadarki süreyi al
    SET @TargetEnd = ISNULL(@ResolvedAt, SYSUTCDATETIME());
    
    IF @TargetEnd < @CreatedAt
        RETURN 0;

    SET @Minutes = DATEDIFF(MINUTE, @CreatedAt, @TargetEnd);

    RETURN @Minutes;
END;
GO