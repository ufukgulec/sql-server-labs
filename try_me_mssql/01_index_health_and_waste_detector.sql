/* ===============================================================================
   Author       : Senior SQL Server DBA / Software Architect
   Description  : Sunucudaki tüm aktif kullanıcı veritabanlarını tarar. 
                  İndeks fragmantasyon oranlarını, boyutlarını ve kullanım 
                  istatistiklerini (Read/Write) analiz ederek aksiyon önerir.
   Target Engine: SQL Server 2012 ve üzeri
   =============================================================================== */

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- Kilitlenmeleri (locking) önlemek için NOLOCK eşdeğeri.

-- 1. Geçici Rapor Tablosunun Hazırlanması
IF OBJECT_ID('tempdb..#IndexHealthReport') IS NOT NULL
    DROP TABLE #IndexHealthReport;

CREATE TABLE #IndexHealthReport (
    DatabaseName         NVARCHAR(128),
    SchemaName           NVARCHAR(128),
    TableName            NVARCHAR(128),
    IndexName            NVARCHAR(128),
    IndexType            NVARCHAR(60),
    AvgFragmentationPct  NUMERIC(5,2),
    PageCount            BIGINT,
    SizeBytesMB          NUMERIC(18, 2),
    TotalReads           BIGINT, -- Seeks + Scans + Lookups (Veri çekme sayısı)
    TotalWrites          BIGINT, -- Updates (Ekleme/Güncelleme/Silme maliyeti)
    RecommendedAction    VARCHAR(50),
    ActionPriority       INT
);

DECLARE @DbName NVARCHAR(128);
DECLARE @Sql NVARCHAR(MAX);

-- 2. Online ve Erişim İzni Olan Kullanıcı Veritabanlarının Listelenmesi
DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT name 
FROM sys.databases 
WHERE database_id > 4               -- System DB'ler pas geçiliyor (master, tempdb vs.)
  AND state_desc = 'ONLINE'         -- Sadece erişilebilir veritabanları
  AND is_read_only = 0
  AND HAS_DBACCESS(name) = 1;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @DbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    /*
      SENIOR NOTE:
      sys.dm_db_index_physical_stats fonksiyonunda 'LIMITED' modu kullanıldı.
      Sakın prod ortamında 'DETAILED' veya 'SAMPLED' yapıp disk I/O'yu patlatmayın.
      'LIMITED' mod sadece parent B-tree sayfalarını okur, ultra hızlıdır.
    */
    SET @Sql = N'
    USE ' + QUOTENAME(@DbName) + N';

    INSERT INTO #IndexHealthReport
    SELECT 
        DB_NAME() AS DatabaseName,
        s.name AS SchemaName,
        t.name AS TableName,
        i.name AS IndexName,
        i.type_desc AS IndexType,
        CAST(ps.avg_fragmentation_in_percent AS NUMERIC(5,2)) AS AvgFragmentationPct,
        ps.page_count AS PageCount,
        CAST((ps.page_count * 8.0) / 1024.0 AS NUMERIC(18,2)) AS SizeBytesMB,
        ISNULL(us.user_seeks + us.user_scans + us.user_lookups, 0) AS TotalReads,
        ISNULL(us.user_updates, 0) AS TotalWrites,
        
        -- Akıllı Aksiyon Karar Mekanizması
        CASE 
            -- 1. Hiç okunmayan ama sürekli INSERT/UPDATE/DELETE yükü çeken ÇÖP indeksler
            WHEN ISNULL(us.user_seeks + us.user_scans + us.user_lookups, 0) = 0 
                 AND ISNULL(us.user_updates, 0) > 500 
                 AND i.is_primary_key = 0 
                 AND i.is_unique = 0
                 AND i.type_desc NOT IN (''CLUSTERED'', ''HEAP'')
                THEN ''DROP CANDIDATE (Unused Index)''

            -- 2. SQL Optimizer 1000 sayfanın (~8MB) altındaki tabloların fragmantasyonunu takmaz (Table Scan yapar).
            -- Buralara Rebuild atmak zaman ve I/O kaybıdır.
            WHEN ps.page_count < 1000 
                THEN ''OK (Too Small < 8MB)''

            -- 3. Yüksek Fragmantasyon (> %30) -> Offline/Online Rebuild Şart
            WHEN ps.avg_fragmentation_in_percent > 30.0 
                THEN ''REBUILD''

            -- 4. Orta Düzey Fragmantasyon (%10 - %30) -> Reorganize kafi
            WHEN ps.avg_fragmentation_in_percent BETWEEN 10.0 AND 30.0 
                THEN ''REORGANIZE''

            ELSE ''OK''
        END AS RecommendedAction,

        CASE 
            WHEN ISNULL(us.user_seeks + us.user_scans + us.user_lookups, 0) = 0 
                 AND ISNULL(us.user_updates, 0) > 500 
                 AND i.is_primary_key = 0 AND i.is_unique = 0 AND i.type_desc NOT IN (''CLUSTERED'', ''HEAP'') THEN 1
            WHEN ps.avg_fragmentation_in_percent > 30.0 AND ps.page_count >= 1000 THEN 2
            WHEN ps.avg_fragmentation_in_percent BETWEEN 10.0 AND 30.0 AND ps.page_count >= 1000 THEN 3
            ELSE 4
        END AS ActionPriority

    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''LIMITED'') ps
    INNER JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
    INNER JOIN sys.tables t ON i.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.dm_db_index_usage_stats us 
        ON ps.database_id = us.database_id 
        AND ps.object_id = us.object_id 
        AND ps.index_id = us.index_id
    WHERE ps.index_id > 0              -- Heap (index_id = 0) tablolar hariç (B-Tree odaklı)
      AND t.is_ms_shipped = 0;         -- Sistem tablolarını pas geç
    ';

    BEGIN TRY
        EXEC sp_executesql @Sql;
    END TRY
    BEGIN CATCH
        -- Hata alan veritabanı olursa (örn. yetki vs.) loglayıp devam et, script patlamasın.
        PRINT 'Hata oluştu DB: ' + @DbName + ' - Hata: ' + ERROR_MESSAGE();
    END CATCH;

    FETCH NEXT FROM db_cursor INTO @DbName;
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- 3. Raporun Öncelik Sırasına Göre Listelenmesi
SELECT 
    DatabaseName,
    SchemaName,
    TableName,
    IndexName,
    IndexType,
    AvgFragmentationPct AS [Frag %],
    PageCount,
    SizeBytesMB AS [Size (MB)],
    TotalReads AS [Total Reads (Select)],
    TotalWrites AS [Total Writes (DML)],
    RecommendedAction
FROM #IndexHealthReport
ORDER BY 
    ActionPriority ASC, 
    SizeBytesMB DESC, 
    AvgFragmentationPct DESC;