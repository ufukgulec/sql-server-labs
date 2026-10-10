# 🏗️ SQL Server Kaizen Management System

Kurumsal süreçlerde sürekli iyileştirme (*Continuous Improvement*) ve yalın üretim felsefesini dijitalleştiren **Kaizen Yönetim Sistemi** için geliştirilmiş Microsoft SQL Server laboratuvarı.

Bu proje; ilişkisel veritabanı tasarımı, T-SQL geliştirme, süreç takibi, maliyet ve kazanç analizi, performans optimizasyonu ve DBA uygulamalarını gerçekçi bir iş senaryosu üzerinden incelemek amacıyla hazırlanmıştır.

## 📌 Proje Hakkında

Kaizen Yönetim Sistemi; çalışanların iyileştirme önerilerini oluşturmasını, ekiplerin projeler üzerinde birlikte çalışmasını, aksiyon planlarının takip edilmesini ve elde edilen sonuçların ölçülmesini sağlayan bir sistemin veritabanı altyapısını modeller.

Proje kapsamında aşağıdaki konular ele alınır:

- İlişkisel veritabanı tasarımı ve normalizasyon
- Primary key, foreign key ve veri bütünlüğü kısıtları
- Stored procedure, view, function ve trigger kullanımı
- Transaction yönetimi ve hata yakalama
- `ROWVERSION` ile optimistic concurrency
- Filtered index ve sorgu optimizasyonu
- Audit log ve süreç geçmişi
- Docker ile SQL Server ortamının kurulması

## 🧩 Veritabanı Mimarisi

Veritabanı, sorumlulukları birbirinden ayırmak amacıyla üç şema üzerine kuruludur:

| Şema | Sorumluluk |
|---|---|
| `org` | Organizasyon yapısı ve çalışan yönetimi |
| `kzn` | Kaizen önerileri, analizler, ekipler, aksiyonlar ve sonuçlar |
| `audit` | Süreç değişiklikleri ve denetim kayıtları |

### 1. Organizasyon Yönetimi — `org`

**Departments**

Departmanları, organizasyonel birimleri ve maliyet merkezlerini tanımlar.

**Employees**

Çalışan bilgilerini, departman ilişkilerini ve aktiflik durumlarını yönetir.

Aktif çalışanların sorgulanmasını desteklemek için uygun filtered index stratejileri kullanılabilir.

### 2. Kaizen Yönetimi — `kzn`

**Kaizens**

Kaizen önerilerinin ve iyileştirme projelerinin ana kayıtlarını tutar.

Öne çıkan özellikler:

- Durum ve öncelik yönetimi
- `CHECK` kısıtlarıyla veri doğrulama
- `ROWVERSION` ile eş zamanlı güncelleme kontrolü

**KaizenTeamMembers**

Kaizen projelerinde görev alan çalışanları ve ekip rollerini yönetir.

Desteklenen örnek roller:

- `LEADER`
- `MEMBER`
- `SPONSOR`

**KaizenAnalyses**

Kök neden analizlerini ve kullanılan analiz yöntemlerini saklar.

Örnek yöntemler:

- `5WHY`
- `FISHBONE`
- `BRAIN_STORMING`

**KaizenActionPlans**

İyileştirme faaliyetlerini, sorumluları ve hedef tamamlanma tarihlerini takip eder.

Tamamlanmamış aksiyonların sorgulanması için filtered index yaklaşımı kullanılabilir.

**KaizenResults**

Kaizen projelerinin ölçülebilir sonuçlarını kaydeder.

Örnek metrikler:

- `FinancialGain`: Finansal kazanç
- `TimeSavedHours`: Kazanılan zaman
- İş güvenliği iyileştirme ölçümleri

### 3. Denetim ve Geçmiş — `audit`

**KaizenLogs**

Kaizen kayıtları üzerindeki süreç değişikliklerini ve ilgili denetim bilgilerini saklar.

Kayıt kapsamı, uygulanan tasarıma bağlı olarak şu bilgileri içerebilir:

- İlgili Kaizen kaydı
- İşlemi gerçekleştiren çalışan
- İşlem türü ve değişiklik bilgileri
- İşlem zamanı
- İstemci IP adresi

## 🔗 İlişkisel Model

Temel ilişkiler aşağıdaki iş modelini destekler:

```text
org.Departments
       │
       └──< org.Employees
                    │
                    ├──< kzn.KaizenTeamMembers >── kzn.Kaizens
                    │                                  │
                    │                                  ├── kzn.KaizenAnalyses
                    │                                  ├──< kzn.KaizenActionPlans
                    │                                  ├── kzn.KaizenResults
                    │                                  └──< audit.KaizenLogs
                    │
                    └── Kaizen aksiyonları için sorumluluk ilişkileri
```

> **Not:** Diyagram kavramsal ilişki yapısını gösterir. Kesin cardinality ve foreign key ilişkileri için SQL şema scriptleri esas alınmalıdır.

## 🚀 SQL Server Nesneleri

Proje, SQL Server'ın farklı veritabanı nesnelerini ve yönetim mekanizmalarını incelemek için uygun bir altyapı sunar.

| Nesne | Kullanım amacı |
|---|---|
| **Tables** | Organizasyon, Kaizen ve denetim verilerini saklamak |
| **Views** | Departman ve proje bazlı raporlama yapmak |
| **Functions** | Hesaplamaları ve tekrar kullanılabilir sorgu mantığını uygulamak |
| **Stored Procedures** | Kontrollü veri ekleme ve güncelleme işlemlerini yürütmek |
| **Triggers** | Belirli veri değişikliklerini denetim kayıtlarına aktarmak |
| **Indexes** | Sorgu performansını iyileştirmek |
| **Constraints** | Veri bütünlüğünü korumak |
| **Transactions** | Birden fazla işlemin tutarlı biçimde yürütülmesini sağlamak |

### Stored Procedures

Stored procedure örneklerinde aşağıdaki konular ele alınabilir:

- `BEGIN TRY...CATCH` ile hata yönetimi
- `BEGIN TRANSACTION`, `COMMIT` ve `ROLLBACK`
- Parametre doğrulama
- Durum geçişlerinin kontrol edilmesi
- Veri bütünlüğünün korunması

### Triggers ve Audit

Kaizen kayıtlarındaki belirli değişikliklerin `audit.KaizenLogs` tablosuna aktarılması için trigger yaklaşımı kullanılabilir.

Trigger tasarımında çok satırlı `INSERT` ve `UPDATE` işlemleri dikkate alınmalıdır.

### SQL Server Agent

SQL Server Agent destekleyen bir ortamda aşağıdaki işler zamanlanabilir:

- Vadesi geçmiş aksiyonların kontrol edilmesi
- Periyodik bakım görevleri
- İndeks ve istatistik bakımının değerlendirilmesi

> SQL Server Agent görevlerinin kullanılabilirliği, SQL Server sürümüne ve çalıştırılan ortama bağlıdır. Docker tabanlı SQL Server kurulumunda ilgili özelliklerin desteklendiği ayrıca doğrulanmalıdır.

## 📁 Proje Yapısı

```text
kaizen/
├── docker/
│   └── docker-compose.yml
├── scripts/
│   ├── 01_schema.sql
│   ├── 02_master_data.sql
│   └── 03_dummy_data.sql
└── README.md
```

### Script Açıklamaları

| Dosya | Açıklama |
|---|---|
| `01_schema.sql` | Veritabanı şemalarını, tabloları, ilişkileri, kısıtları ve tanımlanan diğer veritabanı nesnelerini oluşturur. |
| `02_master_data.sql` | Departmanlar ve diğer referans verileri gibi temel kayıtları ekler. |
| `03_dummy_data.sql` | Çalışanlar, Kaizen projeleri, analizler, aksiyon planları ve sonuçlar için örnek veriler ekler. |

## ⚙️ Gereksinimler

Projeyi çalıştırmak için aşağıdaki araçlar gereklidir:

- [Docker](https://www.docker.com/)
- Docker Compose
- Git
- Terminal veya komut satırı erişimi

Veritabanı ortamı Microsoft SQL Server 2022 için tasarlanmıştır.

## 🛠️ Kurulum

### 1. Repository'yi Klonlayın

```bash
git clone https://github.com/ufukgulec/sql-server-labs.git
cd sql-server-labs/kaizen
```

### 2. SQL Server Container'ını Başlatın

Docker Compose yapılandırmasının bulunduğu dizine geçin:

```bash
cd docker
docker compose up --build -d
```

Container durumunu kontrol edin:

```bash
docker compose ps
```

Logları görüntüleyin:

```bash
docker logs kaizen_sql_server
```

SQL Server'ın başlatıldığını ve sorgu kabul edebildiğini doğrulayın.

### 3. Veritabanı Şemasını Oluşturun

`docker` dizininden aşağıdaki komutla şema scriptini çalıştırabilirsiniz:

```bash
docker exec -i kaizen_sql_server \
  /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P "$SA_PASSWORD" \
  -C \
  -I \
  < ../scripts/01_schema.sql
```

Bu örnekte `SA_PASSWORD` değişkeninin terminal ortamında tanımlanmış olması gerekir.

Örneğin:

```bash
export SA_PASSWORD='YourStrongPassword'
```

> **Güvenlik:** Gerçek parolaları Git repository'sine eklemeyin. Örnek parolaları kendi Docker Compose yapılandırmanızdaki ayarlarla eşleştirin.

**Parametreler:**

| Parametre | Açıklama |
|---|---|
| `-S localhost` | Bağlantı adresini belirtir. |
| `-U sa` | SQL Server kullanıcı adını belirtir. |
| `-P` | Bağlantı parolasını belirtir. |
| `-C` | Sunucu sertifikasına güvenilmesini sağlar. |
| `-I` | `QUOTED_IDENTIFIER` davranışını etkinleştirir. |

### 4. Master Verilerini Yükleyin

```bash
docker exec -i kaizen_sql_server \
  /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P "$SA_PASSWORD" \
  -C \
  < ../scripts/02_master_data.sql
```

### 5. Örnek Verileri Yükleyin

```bash
docker exec -i kaizen_sql_server \
  /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P "$SA_PASSWORD" \
  -C \
  < ../scripts/03_dummy_data.sql
```

> **Önemli:** Scriptlerin doğru veritabanında çalıştığını doğrulayın. `01_schema.sql` veritabanını oluşturuyor ve sonraki scriptler bu veritabanını hedefliyorsa bağlantı hedefini veya scriptlerdeki `USE Kaizen_DB` ifadelerini kontrol edin. Gerekli durumlarda `sqlcmd` komutuna `-d Kaizen_DB` parametresi eklenebilir.

## 🩺 Docker Health Check

Docker yapılandırmasında `sqlcmd` tabanlı bir `HEALTHCHECK` kullanılarak SQL Server'ın sorgu kabul edebilir durumda olup olmadığı kontrol edilebilir.

Bu kontrol, container'ın çalışıyor olması ile veritabanı motorunun hazır olması arasındaki farkı gözetir.

## 📊 Performans ve DBA Laboratuvarları

Bu veritabanı, aşağıdaki konularda uygulamalı çalışmalar yapmak için kullanılabilir.

### Query Optimization

- Actual Execution Plan analizi
- Logical reads ve CPU süresinin ölçülmesi
- Sorgu maliyetlerinin karşılaştırılması
- Filtreleme ve sıralama stratejileri

### Indexing

- Clustered ve nonclustered index'ler
- Composite index tasarımı
- Filtered index kullanımı
- İndekslerin sorgu planına etkisi

### Transaction ve Concurrency

- Transaction yönetimi
- `TRY...CATCH` ile hata yönetimi
- `ROWVERSION` ile optimistic concurrency
- Blocking ve deadlock senaryoları

### Database Maintenance

- İstatistiklerin güncellenmesi
- İndeks bakım stratejileri
- Veritabanı bütünlüğü kontrolleri
- Backup ve restore uygulamaları
- Query Store ile performans izleme

Optimizasyon çalışmalarında amaç yalnızca indeks eklemek değil, sorgu davranışını ölçerek kararları somut sonuçlarla desteklemektir.

## 🧪 Gelecek Geliştirmeler

- [ ] Otomatik SQL testleri
- [ ] tSQLt ile veritabanı birim testleri
- [ ] Şema ve veri bütünlüğü doğrulamaları
- [ ] Query Performance laboratuvarı
- [ ] Transaction, blocking ve deadlock senaryoları
- [ ] Backup ve restore testleri
- [ ] Query Store ile performans analizi
- [ ] GitHub Actions ile otomatik doğrulama
- [ ] Büyük veri kümeleriyle performans testleri

## 🎯 Projenin Amacı

Bu proje, Microsoft SQL Server üzerinde ilişkisel veritabanı tasarımı, T-SQL geliştirme, performans optimizasyonu ve DBA uygulamalarını gerçekçi bir iş alanı üzerinden deneyimlemek amacıyla hazırlanmıştır.

**Temel hedef:** SQL Server özelliklerini yalnızca teorik olarak açıklamak yerine, çalıştırılabilir scriptler, ölçülebilir sonuçlar ve tekrarlanabilir deneylerle ortaya koymak.

---

**Repository:** [ufukgulec/sql-server-labs](https://github.com/ufukgulec/sql-server-labs)