# ITSM Veritabanı Mimarisi ve Şema Dokümantasyonu

Bu doküman, Microsoft SQL Server 2022+ ortamları için geliştirilmiş, üretim (production) standartlarına uygun ilişkisel Bilgi Teknolojileri Hizmet Yönetimi (ITSM) veritabanı şemasının mimari yapısını, tablolar arası ilişkilerini ve veri akışını açıklamaktadır.

🏗️ Mimari Tasarım Prensipleri

    Standartlar: UTC zaman damgaları ve DATETIME2(3) veri tipi kullanımı.   
    SQL

    Performans & Güvenlik: İşlemsel varlıklar için BIGINT IDENTITY anahtarlar, açık kısıtlamalar (PK, FK, UK, CK, DF).   
    SQL

    Veri Bütünlüğü: Yıkıcı (destructive) cascade silme işlemleri yerine yumuşak pasifize etme (Soft Deactivate) yaklaşımı.   
    SQL

    Eşzamanlılık: İyimser eşzamanlılık (optimistic concurrency) yönetimi için ROWVERSION sütunları.   
    SQL

    Audit & Takip: Trigger'lardan bağımsız, uygulama katmanından yönetilen UpdatedAt mekanizmaları ve kapsamlı geçmiş/denetim logları.   
    SQL

📊 Varlık ve İlişki Yapısı (Entity-Relationship)

Şema, operasyonel akışı desteklemek üzere 4 ana modüle ayrılmıştır:
1. Organizasyon ve Kullanıcı Yönetimi

    Departments: Şirket içi departman yapısı (IT, Finans, İK vb.).   
    SQL

    Users: Sistem kullanıcıları. DepartmentId üzerinden departmanlara bağlanır (FK_Users_Departments).   
    SQL

    Roles & UserRoles: Kullanıcıların sistem yetkilerini belirleyen çoka-çok (Many-to-Many) rol yönetimi tablosu.   
    SQL

2. Talep Yönetiminin Omurgası (Tickets)

Sistemin merkezinde yer alan Tickets tablosu, operasyonel süreçleri yönetmek için şu referans tablolara bağlanır:

    Sınıflandırma: TicketTypes (Tip), TicketStatuses (Statü), TicketPriorities (Öncelik) ve Categories (Hiyerarşik kategori yapısı).   
    SQL

    Atama ve Sorumluluk:

        AssignmentGroups (Atama grupları) ve AssignmentGroupMembers (Grup üyeleri).   
        SQL

        Services (İlişkili kurumsal servisler ve servis sahipleri).   
        SQL

        SlaPolicies (Müdahale ve çözüm süresi taahhütleri).   
        SQL

3. Operasyonel Detaylar ve Alt Varlıklar

Talep süreçlerini zenginleştiren ve Tickets tablosuna bağımlı olan alt tablolar:

    TicketComments: İç veya dış paydaş yorumları/notları.   
    SQL

    TicketWorkLogs: Efor ve süre takibi (başlangıç/bitiş, faturalandırılabilirlik).   
    SQL

    TicketAttachments: Güvenli depolama anahtarları ve dosya meta verileri.   
    SQL

    TicketWatchers: Talebi izleyen kullanıcılar.   
    SQL

    TicketTags & Tags: Kolay filtreleme ve etiketleme mekanizması.   
    SQL

    TicketLinks & TicketLinkTypes: Talepler arası ilişki yönetimi (Örn: Engelliyor / İlişkili).   
    SQL

4. Süreç Kontrolü ve Denetim (Audit)

    TicketStatusTransitions: Statüler arası geçiş kurallarını ve izin verilen akışları denetler.   
    SQL

    TicketHistory: Kritik alan değişikliklerini, eski/yeni değerleri ve işlem kaynağını (APPLICATION, API vb.) loglar[cite: 9].

🚀 Performans ve İndeksleme Stratejisi

Yüksek performanslı sorgular ve raporlamalar için şema genelinde şu indeksleme yaklaşımları benimsenmiştir:

    Talep sorgularında hızlı erişim için RequesterId, AssigneeId, AssignmentGroupId ve DepartmentId bazlı filtreleme indeksleri.

    Süre takibi ve SLA denetimleri için DueAt alanı üzerinde optimize edilmiş filtreler.

    INCLUDE komutları ile tablo başına ek veri okuma maliyetini (bookmark lookup) minimuma indiren Covering Index tasarımları.