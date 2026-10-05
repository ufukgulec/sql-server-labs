# SQL Server Labs

Uçtan uca **Microsoft SQL Server** pratiklerini içeren, gerçek dünya senaryolarına yakın örneklerle hazırlanmış SQL Server laboratuvar repository'si.

Bu repository; veritabanı tasarımı, ilişkisel modelleme, indeksleme, sorgu optimizasyonu, transaction yönetimi, bakım operasyonları ve performans analizleri gibi konularda pratik çalışmalar içerir.

## 🎯 Amaç

Bu repository'nin amacı, SQL Server üzerinde yalnızca temel SQL sorguları yazmak yerine, **production ortamlarında karşılaşılabilecek veritabanı problemlerini ve DBA geliştirme pratiklerini** uygulamalı olarak çalışmaktır.

Çalışmalar kapsamında:

* Veritabanı ve şema tasarımı
* Primary Key / Foreign Key ilişkileri
* Normalizasyon
* Constraint tasarımı
* Index stratejileri
* Query optimization
* Execution Plan analizi
* JOIN ve subquery kullanımı
* CTE ve Window Functions
* Transaction yönetimi
* Stored Procedure
* View
* Trigger
* Temporary Table / Table Variable
* Pagination
* Aggregation ve raporlama sorguları
* Deadlock ve concurrency senaryoları
* SQL Server bakım operasyonları
* İstatistik ve index bakım çalışmaları
* Performans analizi

gibi konular ele alınacaktır.

---

# 🏗️ Lab Ortamı

SQL Server, Docker container içerisinde çalıştırılmaktadır.

### Teknolojiler

* **Microsoft SQL Server 2022**
* **Docker**
* **Docker Compose**
* **T-SQL**
* **sqlcmd**
* Linux/macOS Shell

---

# 📁 Repository Yapısı

```text
sql-server-labs/
│
├── 01_database_setup/
│   ├── 01_schemas/
│   │   └── create-itsm-database.sql
│   ├── 02_dummy_data
│   │   └── dummy.sql
│   └── README.md
│
├── 02_queries/
│   ├── basic/
│   ├── joins/
│   ├── aggregations/
│   ├── cte/
│   └── window-functions/
│
├── 03_indexing/
│   ├── indexes.sql
│   └── README.md
│
├── 04_performance/
│   ├── execution-plans/
│   ├── query-optimization/
│   └── README.md
│
├── 05_transactions/
│   ├── transactions.sql
│   └── README.md
│
├── 06_stored_procedures/
│
├── 07_views/
│
├── 08_triggers/
│
├── 09_maintenance/
│
├── docker/
│   └── ...
│
├── docker-compose.yml
├── entrypoint.sh
└── README.md
```

> Repository geliştikçe yeni lab kategorileri eklenebilir.

---

# 🚀 Kurulum

## Gereksinimler

Başlamadan önce aşağıdaki araçların sisteminizde kurulu olması gerekir:

* Docker
* Docker Compose
* Git

Docker'ın çalıştığını kontrol etmek için:

```bash
docker --version
docker compose version
```

---

# 1. Repository'yi Klonla

```bash
git clone https://github.com/ufukgulec/sql-server-labs.git
cd sql-server-labs
```

---

# 2. SQL Server Container'ını Başlat

Docker Compose kullanarak SQL Server ortamını ayağa kaldır:

```bash
docker compose up --build -d
```

Container durumunu kontrol etmek için:

```bash
docker compose ps
```

veya:

```bash
docker ps
```

SQL Server container'ının çalıştığını doğrula:

```bash
docker logs itsm_sql_server
```

SQL Server'ın hazır olduğunu belirten mesaj görülmelidir.

---

# 🗄️ Database Kurulumu

SQL Server container'ı çalıştıktan sonra database oluşturma script'i çalıştırılabilir.

`01_database_setup/01_schemas/create-itsm-database.sql`:

```bash
docker exec -i itsm_sql_server \
/opt/mssql-tools18/bin/sqlcmd \
-S localhost \
-U sa \
-P "Password123" \
-C \
< ./01_database_setup/01_schemas/create-itsm-database.sql
```

Script başarılı şekilde tamamlandığında ITSM database ve ilgili database objects oluşturulur.

---

# 🌱 Dummy Data

Database yapısı oluşturulduktan sonra test/dummy verileri yüklenebilir.

Örneğin:

```bash
docker exec -i itsm_sql_server \
/opt/mssql-tools18/bin/sqlcmd \
-S localhost \
-U sa \
-P "Password123" \
-C \
< ./01_database_setup/02_dummy_data/dummy.sql
```

Bu aşamadan sonra lab ortamında sorgular ve performans çalışmaları gerçekleştirilebilir.

---

# 🔍 Database Kontrolü

SQL Server'a bağlanarak database'lerin oluştuğunu kontrol edebilirsiniz:

```bash
docker exec -it itsm_sql_server \
/opt/mssql-tools18/bin/sqlcmd \
-S localhost \
-U sa \
-P "Password123" \
-C
```

Ardından:

```sql
SELECT name
FROM sys.databases;
GO
```

ITSM database'inin oluştuğu kontrol edilebilir.

---

# 🧩 ITSM Database

İlk lab senaryosu olarak **IT Service Management (ITSM)** tabanlı bir Ticket Management sistemi kullanılmaktadır.

Bu yapı üzerinden gerçek dünyadaki destek/talep yönetimi süreçlerine benzer SQL senaryoları oluşturulmaktadır.

Temel domain:

```text
Company
   │
   ├── Department
   │
   └── User
          │
          ├── Ticket
          │      ├── TicketComment
          │      ├── TicketAttachment
          │      └── TicketHistory
          │
          └── Assignment
```

Örnek ticket lifecycle:

```text
NEW
 │
 ▼
OPEN
 │
 ▼
IN PROGRESS
 │
 ├───────────────┐
 ▼               ▼
RESOLVED       ON HOLD
 │               │
 ▼               └──► IN PROGRESS
CLOSED
```

Bu model ilerleyen lab çalışmalarında:

* JOIN
* GROUP BY
* CTE
* Window Functions
* Indexing
* Execution Plan
* Pagination
* Reporting
* Transaction
* Concurrency

gibi SQL Server konularının uygulanması için kullanılacaktır.

---

# 📚 Lab Yol Haritası

Repository aşağıdaki sırayla ilerleyecek şekilde tasarlanmıştır.

## 01 - Database Setup

Temel database ve relational model oluşturulur.

Konular:

* Database
* Schema
* Tables
* Primary Keys
* Foreign Keys
* Constraints
* Default Values
* Check Constraints
* Relationships
* Seed Data

---

## 02 - Querying

SQL Server sorgu pratiği.

Konular:

* SELECT
* WHERE
* ORDER BY
* GROUP BY
* HAVING
* JOIN
* EXISTS
* IN
* CASE
* Subquery
* CTE
* Window Functions

---

## 03 - Indexing

SQL Server index yapısının ve doğru index tasarımının incelenmesi.

Konular:

* Clustered Index
* Nonclustered Index
* Composite Index
* Included Columns
* Covering Index
* Filtered Index
* Index Selectivity
* Index Maintenance

Örnek:

```sql
CREATE NONCLUSTERED INDEX IX_Ticket_Status_CreatedAt
ON dbo.Ticket (StatusId, CreatedAt)
INCLUDE (PriorityId, AssignedUserId);
```

---

# ⚡ 04 - Performance

SQL Server performans analizleri.

Konular:

* Execution Plan
* Estimated Execution Plan
* Actual Execution Plan
* Table Scan
* Index Scan
* Index Seek
* Key Lookup
* Sort
* Hash Match
* Nested Loops
* Query Cost
* Statistics
* Query Optimization

Örnek çalışma:

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT *
FROM dbo.Ticket
WHERE StatusId = 2;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
```

Amaç, index eklenmeden ve eklendikten sonraki sorgu davranışını karşılaştırmaktır.

---

# 🔐 05 - Transactions & Concurrency

Transaction ve concurrency senaryoları.

Konular:

* BEGIN TRANSACTION
* COMMIT
* ROLLBACK
* TRY / CATCH
* Isolation Levels
* Blocking
* Deadlock
* Locking
* Row Versioning

Örnek:

```sql
BEGIN TRANSACTION;

UPDATE dbo.Ticket
SET StatusId = 2
WHERE TicketId = 1001;

COMMIT TRANSACTION;
```

---

# ⚙️ 06 - Programmability

SQL Server programlama özellikleri.

Konular:

* Stored Procedure
* User Defined Function
* View
* Trigger
* Parameters
* Error Handling
* Dynamic SQL

---

# 🛠️ 07 - Maintenance

SQL Server bakım operasyonları.

Konular:

* Index Rebuild
* Index Reorganize
* Update Statistics
* Database Integrity Check
* Backup
* Restore
* Recovery Models
* Maintenance Jobs

---

# 🧪 Lab Yaklaşımı

Her lab mümkün olduğunca aşağıdaki yapıyı takip eder:

```text
Problem
   ↓
Initial Query
   ↓
Execution Plan / Metrics
   ↓
Analysis
   ↓
Optimization
   ↓
Optimized Query
   ↓
Comparison
   ↓
Conclusion
```

Amaç yalnızca çalışan SQL yazmak değil, **neden o SQL'in tercih edildiğini ve SQL Server'ın sorguyu nasıl çalıştırdığını anlamaktır.**

---

# 🧹 Ortamı Durdurma

Container'ları durdurmak için:

```bash
docker compose down
```

Container'ları durdurup volume'leri de silmek için:

```bash
docker compose down -v
```

> `-v` kullanıldığında SQL Server container'ına bağlı Docker volume'leri silinebilir. Bu nedenle mevcut database verilerinin kaybolabileceğini unutmayın.

---

# 🔄 Ortamı Baştan Oluşturma

Temiz bir lab ortamı oluşturmak için:

```bash
docker compose down -v
docker compose up --build -d
```

Ardından database setup script'i tekrar çalıştırılabilir:

```bash
docker exec -i itsm_sql_server \
/opt/mssql-tools18/bin/sqlcmd \
-S localhost \
-U sa \
-P "Password123" \
-C \
< ./01_database_setup/01_schemas/create-itsm-database.sql
```

Dummy data:

```bash
docker exec -i itsm_sql_server \
/opt/mssql-tools18/bin/sqlcmd \
-S localhost \
-U sa \
-P "Password123" \
-C \
< ./01_database_setup/01_schemas/seed-itsm-database.sql
```

---

# 🔒 Güvenlik Notu

Bu repository'de kullanılan SQL Server `SA` password değeri yalnızca **lokal development/lab ortamı** içindir.

Production ortamlarında:

* `SA` hesabı doğrudan kullanılmamalıdır.
* Güçlü ve güvenli secret yönetimi kullanılmalıdır.
* Password'ler source code veya repository içerisinde tutulmamalıdır.
* Environment variable / Secret Store kullanılmalıdır.
* Minimum privilege prensibi uygulanmalıdır.

Örneğin production ortamında:

```text
Application
    │
    ▼
Application Login
    │
    ├── SELECT
    ├── INSERT
    └── UPDATE
```

uygulanmalı; uygulamaya gereksiz `db_owner` yetkisi verilmemelidir.

---

# 🎯 Hedef

Bu repository'nin nihai amacı, SQL Server üzerinde:

> **Database Design → Querying → Indexing → Performance → Transactions → Maintenance**

zincirinin tamamını uygulamalı olarak gösterebilen bir SQL Server çalışma alanı oluşturmaktır.

Her lab, mümkün olduğunca gerçek dünya problemlerine yakın olacak şekilde hazırlanacaktır.

---

## 📌 Progress

* [x] Docker SQL Server environment
* [x] Database setup
* [x] ITSM relational database
* [x] Dummy / seed data
* [ ] Basic queries
* [ ] Advanced queries
* [ ] Indexing
* [ ] Execution plans
* [ ] Query optimization
* [ ] Transactions
* [ ] Concurrency
* [ ] Stored procedures
* [ ] Views
* [ ] Triggers
* [ ] Backup & Restore
* [ ] Database maintenance
* [ ] Performance labs

---

## 📖 License

This repository is intended for educational and practical SQL Server exercises.
