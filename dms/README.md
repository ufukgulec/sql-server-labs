# 🏗️ SQL Server DMS Projesi ve Mimarisi

Bu repository, gerçek dünya senaryolarına dayalı bir Doküman Yönetim Sistemi (Document Management System - DMS) domainini ele alan, uçtan uca bir Microsoft SQL Server laboratuvar ve pratik alanıdır. Proje; veritabanı tasarımı, ilişkisel modelleme, HIERARCHYID kullanımı, versiyonlama stratejileri, performans optimizasyonu ve veritabanı yönetim sistemleri (DBA) pratiklerini uygulamalı olarak geliştirmek amacıyla tasarlanmıştır.

## 🧩 Veritabanı İlişkileri ve Mimari Yapı
Proje, kurumsal düzeyde bir doküman ve klasör yönetim sisteminin ihtiyaç duyduğu modüler şema yapısına (`sec`, `dms`, `audit`) sahiptir:

- **Kimlik ve Yetkilendirme (`sec` Şeması):**
  - `Users` & `Groups`: Kullanıcılar ve kurumsal gruplar/departmanlar tanımlanır.
  - `UserGroups`: Kullanıcı ve gruplar arasındaki çoka-çok ilişkiyi yönetir.
  - `AccessControlLists` (ACL): Klasör veya doküman bazında granular yetkilendirme (Okuma, Yazma, Silme, Yetki Değiştirme) sağlar. Mükerrer kaydı önlemek için Filtered Index'ler barındırır.

- **Doküman ve Klasör Yönetimi (`dms` Şeması):**
  - `Folders`: `HIERARCHYID` veri tipi ve `Level` hesaplanmış kolonu (persisted computed column) ile sınırsız derinlikte klasör hiyerarşisi sunar.
  - `Documents`: Doküman ana verilerini tutar. İyimser eşzamanlılık (Optimistic Concurrency) için `ROWVERSION`, çakışmalı düzenlemeleri önlemek için `IsLocked` / `LockedBy` yapısını ve yumuşak silme (`IsDeleted`) desteğini barındırır.
  - `DocumentVersions`: Değiştirilemez (Immutable) versiyonlama mimarisine sahiptir. Dosya boyutu, depolama sağlayıcısı (`AWS_S3`, `AZURE_BLOB`, `LOCAL_FILE`) ve SHA-256 bütünlük doğrulaması (`FileHash`) bilgilerini tutar.
  - `DocumentMetadata`: Dokümanlara dinamik etiket/anahtar-değer çiftleri (Key-Value) eklenmesini sağlar.

- **Tarihçe ve Denetim (`audit` Şeması):**
  - `DocumentLogs`: Doküman üzerinde gerçekleşen tüm işlemleri (`CREATED`, `VIEWED`, `DOWNLOADED`, `VERSION_ADDED`, `LOCKED`) yapan kullanıcı ve IP adresi detaylarıyla kayıt altına alır.

## 🚀 Gelişmiş Veritabanı Nesneleri ve Programatik Mimari
Projenin altyapısı; kurumsal standartlara uygun tam donanımlı bir DBA ve Backend laboratuvarı olarak tasarlanmıştır:
- **Views (Görünümler):** Klasör hiyerarşi ağaçları, en güncel doküman versiyon detayları ve erişim kontrol matrislerini sunan performans odaklı görünümler.
- **Functions (Fonksiyonlar):** `HIERARCHYID` yolunu text formatına çeviren, kullanıcıların doküman/klasör üzerindeki etkin yetkilerini (`CanRead`, `CanWrite`) kontrol eden fonksiyonlar.
- **Stored Procedures (Saklı Yordamlar):** `BEGIN TRY...CATCH` ve `TRANSACTION` blokları ile güvenli doküman yükleme, versiyon artırma, kilitleme (`Check-out` / `Check-in`) ve yetki atama yordamları.
- **Triggers (Tetikleyiciler):** Doküman güncellemeleri ve statü değişimlerini otomatik olarak `audit.DocumentLogs` tablosuna aktaran yapılar.
- **Jobs (SQL Agent Görevleri):** Veritabanı performansını korumak için periyodik indeks bakımı, yetim kalmış (orphaned) versiyon temizlikleri ve dosya hash bütünlük doğrulama taramaları.

## 🛠️ Kurulum ve Çalıştırma Adımları

> [!IMPORTANT]
> İşlemlere başlamadan önce sisteminizde Docker ve Docker Compose servislerinin kurulu ve aktif olduğundan emin olun.

- Monorepo ve Klasör Ayrımı: Proje yapılandırması docker/, scripts/ ve veritabanı kurulum dosyaları şeklinde modüler hale getirilmiştir.

- Kapsamlı Master ve Gelişmiş Dummy Veriler:
    - Sistem ayarları, statüler, roller ve tipler gibi zorunlu ana veriler ayrıştırılmıştır.
    - Gelişmiş test senaryolarını simüle etmek adına çok sayıda kullanıcı, farklı departmanlar, zengin bilet senaryoları, worklog'lar, audit geçmişleri ve dosya ekleri eklenmiştir.

- Docker Sağlık Kontrolü (Healthcheck): SQL Server container'ının sadece çalışıyor olması değil, veritabanı motorunun sorgu kabul edebilir seviyeye gelmesi sqlcmd tabanlı HEALTHCHECK mekanizmasıyla güvence altına alınmıştır.

- Performans ve İndeksleme Altyapısı: İlerleyen aşamalarda Execution Plan, Index Stratejileri, Transaction Yönetimi ve Query Optimization çalışmalarının yapılabilmesi için uygun ilişkisel zemin hazırlanmıştır.

## 🎯 Geliştirmeci İçin Eklenenler ve Yenilikler
Projeyi kendi yerel ortamınızda Docker kullanarak adım adım ayağa kaldırmak için aşağıdaki adımları izleyebilirsiniz:
1. Repository'yi Klonlayın
```bash
git clone https://github.com/ufukgulec/sql-server-labs.git
cd sql-server-labs
```
2. Docker Container'ı Başlatın
Docker Compose kullanarak SQL Server 2022 ortamını ark planda build edin ve ayağa kaldırın:
```bash
cd docker
docker compose up --build -d
```
Container'ın durumunu ve loglarını kontrol etmek için:
```bash
docker compose ps
docker logs dms_sql_server
```
3. Veritabanı Şemasını Oluşturun
SQL Server ayağa kalktıktan sonra, DMS_DB veritabanını ve şemalarını oluşturmak için script'i -I (QUOTED_IDENTIFIER) parametresiyle çalıştırın:
```bash
docker exec -i dms_sql_server \
  /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P "Password123" \
  -C \
  -I \
  < ../scripts/01_schema.sql
```
4. Test (Dummy) Verilerini Yükleyin
-   Sistemi test etmek ve hazır verilerle çalışmak için master data script'ini execute edin:
```bash
docker exec -i dms_sql_server \
/opt/mssql-tools18/bin/sqlcmd \
-S localhost \
-U sa \
-P "Password123" \
-C \
< ../scripts/02_master_data.sql
```
- Sistemi test etmek ve hazır verilerle çalışmak için dummy data script'ini execute edin:
```bash
docker exec -i dms_sql_server \
/opt/mssql-tools18/bin/sqlcmd \
-S localhost \
-U sa \
-P "Password123" \
-C \
< ../scripts/03_dummy_data.sql
```
Bu adımların ardından veritabanınız tüm ilişkisel tabloları ve örnek verileriyle birlikte kullanıma hazır hale gelecektir.

5. Programatik Nesneleri (Views, Functions, Procedures, Triggers) Entegre Edin
Gelişmiş modülleri sırasıyla veritabanına tanımlayabilirsiniz.