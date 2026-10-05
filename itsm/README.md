# 🏗️ SQL Server ITSM Projesi ve Mimarisi

Bu repository, gerçek dünya senaryolarına dayalı IT Service Management (ITSM) domainini ele alan, uçtan uca bir Microsoft SQL Server laboratuvar ve pratik alanıdır. Proje; veritabanı tasarımı, ilişkisel modelleme, performans optimizasyonu ve veritabanı yönetim sistemleri (DBA) pratiklerini uygulamalı olarak geliştirmek amacıyla tasarlanmıştır.

## 🧩 Veritabanı İlişkileri ve Mimari Yapı
Proje, kurumsal düzeyde bir destek ve talep yönetim sisteminin (ITSM) ihtiyaç duyduğu ilişkisel tabloları barındırır. Temel domain yapısı şu şekildedir:

- Şirket ve Organizasyon: Sistem içerisinde kullanıcılar (`Users`) belirli departmanlara (`Departments`) bağlı olarak çalışır.
- Rol Yetkilendirme: Kullanıcılar ile roller (`Roles`) çoka-çok (`UserRoles`) ilişki yapısıyla bağlanmıştır.
- Talep (`Ticket`) Yaşam Döngüsü:
- Her talep bir kullanıcı (`Requester`) tarafından oluşturulur.
    - Talepler kategori (`Categories`), servis (`Services`), öncelik (`TicketPriorities`), statü (`TicketStatuses`) ve SLA politikalarına (`SlaPolicies`) bağlanır.
    - Talepler belirli atama gruplarına (`AssignmentGroups`) veya bireysel personele (`AssigneeId`) atanabilir.
- Detay Modülleri: Biletlere bağlı olarak çalışan alt bileşenler mevcuttur:
- Talepler belirli atama gruplarına (`AssignmentGroups`) veya bireysel personele (`AssigneeId`) atanabilir.
    - TicketComments: Bilet içi yazışmalar ve notlar.
    - TicketAttachments: Biletlere yüklenen dosya ve ekler.
    - TicketHistory (`Audit`): Bilet üzerinde yapılan değişikliklerin ve statü geçişlerinin loglandığı tarihçe tablosu.
    - TicketWorkLogs: Harcanan zamanın ve çalışma loglarının takibi.
    - TicketLinks: Biletler arasındaki ilişkiler (örn. bir arızanın başka bir talebi engellemesi - BLOCKS, RELATES).

## 🚀 Gelişmiş Veritabanı Nesneleri ve Programatik Mimari
Projenin altyapısı; sadece tablo tutan bir yapıdan çıkarılıp, kurumsal standartlara uygun tam donanımlı bir DBA ve Backend laboratuvarına dönüştürülmüştür:
-   Views (Görünümler): Karmaşık JOIN maliyetlerini ortadan kaldıran, arayüz ve raporlama katmanı için optimize edilmiş bilet detayları, personel iş yükleri ve SLA özet görünümleri (vw_TicketDetails, vw_UserWorkloads, vw_SlaStatusSummary).

-   Functions (Fonksiyonlar): İş günü/saat bazlı bitiş tarihi hesaplayan (fn_CalculateBusinessDueDate), isim formatlayan, bilet yaşını hesaplayan ve grup üyelik yetkilerini kontrol eden deterministik fonksiyonlar.

-   Stored Procedures (Saklı Yordamlar): BEGIN TRY...CATCH ve TRANSACTION blokları ile veri bütünlüğünü garanti eden, güvenli bilet oluşturma, atama ve çözümleme yordamları (sp_CreateTicket, sp_AssignTicket, sp_ResolveTicket).

-   Triggers (Tetikleyiciler): Bilet güncellemelerini ve statü değişimlerini otomatik olarak audit eden tetikleyici mekanizmalar (trg_TicketAudit).

-   Jobs (SQL Agent Görevleri): Veritabanı performansını korumak için periyodik indeks bakım (Index Maintenance) ve saatlik SLA ihlal tarama görevleri (SLA Breach Check).

## 🛠️ Kurulum ve Çalıştırma Adımları
Projenin altyapısı ve geliştirme süreçleri, profesyonel bir DBA ve backend geliştiricinin ihtiyaç duyacağı şekilde zenginleştirilmiştir:

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
docker logs itsm_sql_server
```
3. Veritabanı Şemasını Oluşturun
SQL Server ayağa kalktıktan sonra, veritabanı şema ve tablo oluşturma script'ini çalıştırın:
```bash
docker exec -i itsm_sql_server \
/opt/mssql-tools18/bin/sqlcmd \
-S localhost \
-U sa \
-P "Password123" \
-C \
< ../scripts/01_schema.sql
```
4. Test (Dummy) Verilerini Yükleyin
-   Sistemi test etmek ve hazır verilerle çalışmak için master data script'ini execute edin:
```bash
docker exec -i itsm_sql_server \
/opt/mssql-tools18/bin/sqlcmd \
-S localhost \
-U sa \
-P "Password123" \
-C \
< ../scripts/02_master_data.sql
```
- Sistemi test etmek ve hazır verilerle çalışmak için dummy data script'ini execute edin:
```bash
docker exec -i itsm_sql_server \
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