/* ============================================================
   FUNCTION: itsm.fn_FormatFullName
   Amaç: Ad ve soyad bilgilerini standart bir formata getirir.
   ============================================================ */

CREATE FUNCTION itsm.fn_FormatFullName
(
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100)
)
RETURNS NVARCHAR(201)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @FormattedName NVARCHAR(201);

    SET @FormattedName = LTRIM(RTRIM(ISNULL(@FirstName, N''))) + N' ' + LTRIM(RTRIM(ISNULL(@LastName, N'')));

    IF LEN(@FormattedName) <= 1
        SET @FormattedName = N'Bilinmeyen Kullanıcı';

    RETURN @FormattedName;
END;
GO