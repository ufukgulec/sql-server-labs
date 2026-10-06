# SQL Server Labs

Uçtan uca **Microsoft SQL Server** pratiklerini içeren, gerçek dünya senaryolarına yakın örneklerle hazırlanmış SQL Server laboratuvar repository'si.

Bu repository; yalnızca SQL sorguları yazmayı değil, **veritabanı tasarımı, ilişkisel modelleme, performans optimizasyonu, transaction yönetimi, indeksleme ve SQL Server bakım operasyonlarını** uygulamalı olarak ele alır.

## 🎯 Amaç

Bu repository'nin temel amacı, SQL Server üzerinde production ortamlarında karşılaşılabilecek problemlere yönelik pratik çalışmalar gerçekleştirmektir.

Çalışmalar; bir yazılım geliştiricinin SQL Server ile çalışırken ihtiyaç duyacağı **database development** ve **DBA** konularını birlikte ele alacak şekilde ilerlemektedir.

Başlıca konular:

* Veritabanı ve şema tasarımı
* İlişkisel veri modelleme
* Normalizasyon
* Primary Key / Foreign Key tasarımı
* Unique, Check ve Default Constraints
* Referential Integrity
* Index stratejileri
* Query Optimization
* Execution Plan analizi
* JOIN ve Subquery
* CTE
* Window Functions
* Aggregation ve raporlama
* Pagination
* Stored Procedure
* View
* Trigger
* Temporary Table / Table Variable
* Transaction yönetimi
* Concurrency
* Deadlock senaryoları
* İstatistik ve index bakımı
* SQL Server bakım operasyonları
* Performans analizi

---

## 🗂️ Repository Yapısı

```text
sql-server-labs/
│
├── dms/
│   └── ...
│
├── itsm/
│   └── ...
│
├── try_me_mssql/
│   └── ...
│
└── README.md
```

### `itsm`

Gerçek dünya senaryosuna yakın bir **IT Service Management (ITSM)** veritabanı üzerinde SQL Server database design ve geliştirme çalışmaları.

Bu bölümde;

* İlişkisel veritabanı tasarımı
* Entity ilişkileri
* Primary / Foreign Key
* Constraint'ler
* Index tasarımı
* Audit ve timestamp alanları
* Soft delete / pasifleştirme
* Ticket ve talep yönetimi
* Kullanıcı, ekip ve kategori yapıları
* SQL Server performans yaklaşımları

gibi konular ele alınır.

Amaç, yalnızca çalışan bir şema oluşturmak değil, **production ortamında sürdürülebilir bir veritabanı tasarlamaktır.**

### `dms`

**Document Management System (DMS)** senaryosu üzerinden SQL Server uygulamalarını ve ilişkisel veri modelleme yaklaşımlarını incelemek için kullanılan çalışma alanıdır.

Doküman, kullanıcı, kategori, versiyonlama ve ilişkili metadata gibi yapıların SQL Server üzerinde modellenmesi ve yönetilmesine yönelik çalışmalar burada tutulur.

### `try_me_mssql`

SQL Server özelliklerini, T-SQL ifadelerini ve farklı veritabanı senaryolarını hızlı şekilde denemek için kullanılan **sandbox / experimentation** alanıdır.

Yeni bir SQL özelliğini veya sorgu yaklaşımını ana projelere dahil etmeden önce burada test etmek mümkündür.

---

## 🐳 Lab Ortamı

Çalışmaların mümkün olduğunca tekrar üretilebilir olması amacıyla SQL Server, Docker container içerisinde çalıştırılmaktadır.

### Kullanılan Teknolojiler

| Teknoloji                      | Kullanım                        |
| ------------------------------ | ------------------------------- |
| **Microsoft SQL Server 2022+** | Veritabanı platformu            |
| **T-SQL**                      | Database development            |
| **Docker**                     | SQL Server çalışma ortamı       |
| **Docker Compose**             | Container orchestration         |
| **sqlcmd**                     | SQL Server CLI                  |
| **Linux / macOS Shell**        | Otomasyon ve yardımcı scriptler |

SQL Server'ın Docker üzerinde çalıştırılması, geliştirme ortamının hızlı şekilde oluşturulmasını ve gerektiğinde yeniden kurulabilmesini sağlar.

---

## 🚀 Başlangıç

Repository'yi klonlayın:

```bash
git clone https://github.com/ufukgulec/sql-server-labs.git

cd sql-server-labs
```

Docker container'larını başlatın:

```bash
docker compose up --build -d
```

Çalışan container'ları kontrol edin:

```bash
docker ps
```

SQL Server container'ına bağlanmak için:

```bash
docker exec -it itsm_sql_server /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P '<password>' \
    -C
```

> Container adı ve bağlantı bilgileri ilgili lab'ın Docker yapılandırmasına göre değişebilir.

---

## 🧱 Database Design Yaklaşımı

Repository içerisindeki database tasarımlarında mümkün olduğunca production ortamlarında kullanılan yaklaşımlar tercih edilir.

Örneğin:

* `BIGINT IDENTITY` primary key kullanımı
* Açık şekilde tanımlanmış `PK`, `FK`, `UK`, `CK` ve `DF` constraint'leri
* `DATETIME2` ile UTC timestamp kullanımı
* `ROWVERSION` ile optimistic concurrency
* Foreign key ilişkilerinin açık şekilde tanımlanması
* Gereksiz `ON DELETE CASCADE` kullanımından kaçınılması
* Reference tablolarında soft deactivate yaklaşımı
* Sorgu modellerine göre index tasarımı
* Foreign key ve sık kullanılan filtre alanlarının indekslenmesi
* Veri bütünlüğünün database seviyesinde korunması

Temel hedef:

> **Çalışan bir database değil, sürdürülebilir ve production'a yakın bir database tasarlamak.**

---

## ⚡ Performance & Query Optimization

SQL Server performansı yalnızca index eklemekten ibaret değildir.

Bu repository içerisinde performans aşağıdaki başlıklar üzerinden incelenmektedir:

```text
Query
  ↓
Execution Plan
  ↓
Index Analysis
  ↓
Statistics
  ↓
I/O & CPU
  ↓
Query Optimization
```

Çalışmalarda gerektiğinde:

* Execution Plan
* Index Seek / Index Scan
* Key Lookup
* Table Scan
* Logical Reads
* CPU Time
* Statistics
* Cardinality
* Query cost

gibi SQL Server performans göstergeleri incelenir.

---

## 🔄 Transaction & Concurrency

Gerçek uygulamalarda birden fazla transaction'ın aynı anda çalışması veri tutarlılığı ve performans açısından kritik olabilir.

Bu nedenle repository kapsamında;

* Transaction yönetimi
* Isolation Level
* Locking
* Blocking
* Deadlock
* Concurrency
* Optimistic concurrency

gibi konular da ele alınacaktır.

---

## 🛠️ SQL Server Maintenance

Database yalnızca oluşturulup bırakılmaz.

Bakım çalışmalarında aşağıdaki konulara yer verilecektir:

* Index fragmentation
* Index rebuild / reorganize
* Statistics update
* Database integrity checks
* Backup / restore senaryoları
* Query performance monitoring
* Database health kontrolleri

Amaç, SQL Server'ın yalnızca development aşamasını değil, **operasyonel yaşam döngüsünü** de incelemektir.

---

## 📚 Öğrenme Alanları

Repository ilerledikçe aşağıdaki alanlarda örnekler eklenmesi hedeflenmektedir:

```text
Database Design
      │
      ├── Data Modeling
      ├── Normalization
      ├── Constraints
      └── Relationships
             │
             ▼
        T-SQL Development
             │
             ├── Queries
             ├── CTE
             ├── Window Functions
             ├── Procedures
             ├── Views
             └── Triggers
             │
             ▼
        Performance
             │
             ├── Indexes
             ├── Statistics
             ├── Execution Plans
             └── Query Optimization
             │
             ▼
        Operations
             │
             ├── Transactions
             ├── Concurrency
             ├── Deadlocks
             ├── Backup / Restore
             └── Maintenance
```

---

## 🎯 Repository'nin Kapsamı

Bu repository bir SQL Server tutorial'ından ziyade, **uygulamalı bir SQL Server çalışma alanı** olarak tasarlanmıştır.

Özellikle aşağıdaki yetkinlikleri göstermek amacıyla oluşturulmuştur:

* SQL Server database development
* Relational database design
* T-SQL
* Query optimization
* Index design
* Performance analysis
* Transaction management
* Database maintenance
* DBA fundamentals
* Production-oriented database practices

---

## 📌 Not

Bu repository'deki çalışmalar **eğitim, deneysel geliştirme ve teknik portföy** amacıyla hazırlanmıştır.

Production ortamında kullanılacak sistemlerde; veri hacmi, workload, SQL Server Edition, donanım, execution plan'lar, mevcut index'ler, concurrency modeli ve uygulama davranışı gibi faktörler ayrıca değerlendirilmelidir.

---

## 📄 License

This repository is intended for educational and practical SQL Server exercises.

---

## 👤 Author

**Orhan Ufuk Güleç**

Software Developer
.NET & SQL Server

GitHub:
https://github.com/ufukgulec
