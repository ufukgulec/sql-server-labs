# 🏗️ SQL Server Kaizen Yönetim Projesi ve Mimarisi

Bu repository, kurumsal süreçlerde sürekli iyileştirme (**Continuous Improvement**) ve yalın üretim felsefesini dijitalleştiren bir **Kaizen Yönetim Sistemi (Kaizen Management System)** domainini ele alan, uçtan uca bir Microsoft SQL Server laboratuvarı ve pratik alanıdır.

Proje; veritabanı tasarımı, ilişkisel modelleme, süreç akış takibi, maliyet ve kazanç ölçümlemesi, performans optimizasyonu ve veritabanı yönetimi (**DBA**) pratiklerini uygulamalı olarak geliştirmek amacıyla tasarlanmıştır.

## 🧩 Veritabanı İlişkileri ve Mimari Yapı

Proje, kurumsal düzeyde bir öneri ve iyileştirme takip sisteminin ihtiyaç duyduğu modüler şema yapısına (`org`, `kzn`, `audit`) sahiptir.

### 1. Organizasyon ve Kimlik Yönetimi (`org` Şeması)

- **`Departments`:** Fabrika veya şirket departmanlarını ve maliyet merkezlerini (*Cost Center*) tanımlar.
- **`Employees`:** Sistemi kullanan çalışanları, departman ilişkilerini ve aktiflik durumlarını yönetir. Aktif çalışan sorguları için optimize edilmiş filtered index'ler içerir.

### 2. Kaizen ve İyileştirme Yönetimi (`kzn` Şeması)

- **`Kaizens`:** Kaizen önerilerinin ve projelerinin temel verilerini tutar. İyimser eşzamanlılık (*Optimistic Concurrency*) için `ROWVERSION`; durum ve öncelik takibi için `CHECK` kısıtları içerir.
- **`KaizenTeamMembers`:** Bir Kaizen projesinde görev alan çalışanlar arasındaki çoka-çok ilişkiyi ve ekip rollerini (`LEADER`, `MEMBER`, `SPONSOR`) yönetir.
- **`KaizenAnalyses`:** Problemlerin kök neden analizlerini ve kullanılan yöntemleri (`5WHY`, `FISHBONE`, `BRAIN_STORMING`) birebir ilişkiyle saklar.
- **`KaizenActionPlans`:** İyileştirme faaliyetlerini, sorumluları ve vade tarihlerini takip eder. Tamamlanmamış aksiyonlar için filtered index desteği sunar.
- **`KaizenResults`:** Kaizen sonucunda elde edilen finansal kazancı (`FinancialGain`), zaman tasarrufunu (`TimeSavedHours`) ve iş güvenliği iyileştirme skorlarını ölçümler.

### 3. Tarihçe ve Denetim (`audit` Şeması)

- **`KaizenLogs`:** Kaizen kayıtları üzerinde gerçekleşen süreç değişikliklerini ve onay adımlarını; işlemi gerçekleştiren çalışan ve IP adresi bilgileriyle kayıt altına alır.

## 🚀 Gelişmiş Veritabanı Nesneleri ve Programatik Mimari

Proje, kurumsal standartları ve DBA uygulamalarını incelemek üzere aşağıdaki SQL Server nesnelerini ve mekanizmalarını kapsayacak şekilde tasarlanmıştır.

| Nesne / Mekanizma | Açıklama |
|---|---|
| **Views** | Departman bazlı Kaizen özetleri, aktif projeler ve kazanım raporları sunar. |
| **Functions** | Çalışan performans metriklerini ve Kaizen tamamlama sürelerini hesaplayan yardımcı fonksiyonlar sağlar. |
| **Stored Procedures** | `BEGIN TRY...CATCH` ve `TRANSACTION` bloklarıyla güvenli Kaizen oluşturma, durum güncelleme ve sonuç doğrulama işlemlerini yönetir. |
| **Triggers** | Kaizen durum değişikliklerini ve güncellemelerini `audit.KaizenLogs` tablosuna aktarır. |
| **SQL Server Agent Jobs** | Vadesi geçmiş aksiyon planlarını denetleme ve periyodik indeks bakımı gibi arka plan görevlerini ele alır. |

## 🛠️ Proje Yapısı

Proje yapılandırması Docker, SQL scriptleri ve veritabanı kurulum adımlarını birbirinden ayıracak şekilde modüler olarak düzenlenmiştir.

```text
sql-server-labs/
├── docker/
│   └── docker-compose.yml
├── scripts/
│   ├── 01_schema.sql
│   ├── 02_master_data.sql
│   └── 03_dummy_data.sql
└── README.md
```
Not: Yukarıdaki dizin yapısı temel proje düzenini gösterir. Gerçek repository yapınızla dosya ve klasör adlarının eşleştiğinden emin olun.

Script Açıklamaları
Dosya	Açıklama
01_schema.sql	Kaizen_DB veritabanını, şemaları, tabloları, ilişkileri, kısıtları ve ilgili veritabanı nesnelerini oluşturur.
02_master_data.sql	Departmanlar ve diğer zorunlu referans verileri gibi temel kayıtları ekler.
03_dummy_data.sql	Çalışanlar, Kaizen projeleri, kök neden analizleri, aksiyon planları ve kazanım ölçümleri için örnek veriler oluşturur.


⚙️ Gereksinimler
Projeyi çalıştırmadan önce aşağıdaki araçların sisteminizde kurulu olduğundan emin olun:
- Docker
- Docker Compose
- Git
- Terminal veya komut satırı erişimi
Proje, Microsoft SQL Server 2022 üzerinde çalışacak şekilde tasarlanmıştır.
🎯 Kurulum ve Çalıştırma
1. Repository'yi Klonlayın
git clone https://github.com/ufukgulec/sql-server-labs.git
cd sql-server-labs

2. SQL Server Container'ını Başlatın
Docker Compose yapılandırmasının bulunduğu klasöre geçin ve container'ı arka planda başlatın:
cd docker
docker compose up --build -d

Container durumunu kontrol edin:
docker compose ps

Container loglarını görüntüleyin:
docker logs kaizen_sql_server

SQL Server'ın tamamen başlatıldığından ve bağlantı kabul edebildiğinden emin olun.
3. Veritabanı Şemasını Oluşturun
SQL Server hazır olduktan sonra Kaizen_DB veritabanını ve ilgili şemaları oluşturmak için aşağıdaki komutu çalıştırın:
docker exec -i kaizen_sql_server \
  /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P "Password123" \
  -C \
  -I \
  < ../scripts/01_schema.sql

Parametreler:
- -S localhost: SQL Server bağlantı adresi.
- -U sa: SQL Server yönetici hesabı.
- -P: Bağlantı parolası.
- -C: Sunucu sertifikasına güvenilmesini sağlar.
- -I: QUOTED_IDENTIFIER davranışını etkinleştirir.
- -i veya standart girdi yönlendirmesi: SQL scriptinin çalıştırılmasını sağlar.
Güvenlik uyarısı: Password123 yalnızca örnek bir paroladır. Gerçek ortamlarda güçlü parola kullanın ve parolaları repository içerisinde saklamayın. Yerel geliştirme ortamında da mümkün olduğunca environment variable veya uygun bir secret mekanizması tercih edin.

4. Master Verilerini Yükleyin
Departmanlar ve diğer temel referans verilerini oluşturmak için:
docker exec -i kaizen_sql_server \
  /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P "Password123" \
  -C \
  < ../scripts/02_master_data.sql

5. Örnek (Dummy) Verileri Yükleyin
Gelişmiş test senaryolarını simüle etmek için:
docker exec -i kaizen_sql_server \
  /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P "Password123" \
  -C \
  < ../scripts/03_dummy_data.sql

Bu adımların ardından veritabanı; ilişkisel tabloları, kısıtları ve örnek verileriyle birlikte kullanıma hazır olacaktır.
Önemli: Scriptlerin hangi veritabanında çalıştığını doğrulayın. Gerekirse bağlantı komutlarına -d Kaizen_DB parametresini ekleyin. Kurulum scriptleri bu veritabanını oluşturuyorsa ilk şema scriptinde bu parametreyi kullanmadan önce bağlantı hedefini kontrol edin.

🩺 Docker Sağlık Kontrolü
Docker yapılandırmasında SQL Server container'ının yalnızca çalışıyor olmasını değil, veritabanı motorunun sorgu kabul edebilir durumda olmasını da doğrulayan sqlcmd tabanlı bir HEALTHCHECK mekanizması kullanılabilir.
Bu yaklaşım, container'ın başlatılması ile veritabanının gerçekten hazır olması arasındaki farkı gözetir.
📊 Performans ve İndeksleme Çalışmaları
Veritabanı şeması, aşağıdaki konularda uygulamalı deneyler yapılmasına uygun bir zemin sunar:
- Execution Plan analizi
- Clustered ve nonclustered index stratejileri
- Filtered index kullanımı
- Sorgu optimizasyonu
- Logical reads ve CPU süresi ölçümü
- Transaction yönetimi
- Eş zamanlı veri güncellemeleri
- ROWVERSION ile optimistic concurrency
- İndeks ve istatistik bakımı
Bu çalışmalarda amaç yalnızca indeks oluşturmak değil, sorguların davranışını ölçmek ve optimizasyon kararlarını gerçek sonuçlarla desteklemektir.
🧪 Gelecek Geliştirmeler
Proje zaman içerisinde aşağıdaki laboratuvarlarla genişletilebilir:
- [ ] Otomatik SQL testleri ve veri bütünlüğü kontrolleri
- [ ] tSQLt ile veritabanı birim testleri
- [ ] Query Performance ve Execution Plan laboratuvarı
- [ ] Transaction, blocking ve deadlock senaryoları
- [ ] Backup ve restore uygulamaları
- [ ] Query Store ile performans izleme
- [ ] GitHub Actions ile otomatik SQL doğrulama
- [ ] Büyük veri kümeleriyle performans testleri
🎯 Projenin Amacı
Bu proje, Microsoft SQL Server üzerinde ilişkisel veritabanı tasarımı, T-SQL geliştirme, performans optimizasyonu ve DBA uygulamalarını gerçekçi bir iş alanı üzerinden deneyimlemek amacıyla geliştirilmiştir.
Temel hedef: SQL Server özelliklerini yalnızca teorik olarak açıklamak yerine, çalıştırılabilir scriptler, ölçülebilir sonuçlar ve tekrarlanabilir deneylerle ortaya koymak.
