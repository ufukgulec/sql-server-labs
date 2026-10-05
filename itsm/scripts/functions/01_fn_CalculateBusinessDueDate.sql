/* ============================================================
   FUNCTION: itsm.fn_CalculateBusinessDueDate
   Amaç: Belirtilen başlangıç tarihine, SLA dakika süresini 
         ekleyerek hedef bitiş (DueAt) tarihini hesaplar.
   ============================================================ */

CREATE FUNCTION itsm.fn_CalculateBusinessDueDate
(
    @StartDate DATETIME2(3),
    @DurationMinutes INT
)
RETURNS DATETIME2(3)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @CalculatedDate DATETIME2(3);
    
    -- Basit ve güvenli bir ekleme mantığı (İhtiyaca göre mesai saatleri/tatiller buraya eklenebilir)
    SET @CalculatedDate = DATEADD(MINUTE, @DurationMinutes, @StartDate);

    RETURN @CalculatedDate;
END;
GO