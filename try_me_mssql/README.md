## 🩺 MSSQL Server Production Healthcheck Tools

Canlı ortamlarda (Production) kilitlenme yaratmadan, I/O dostu (`LIMITED` / `READ UNCOMMITTED`) analiz yapan senior düzey teşhis ve performans izleme script'leri.

| Script | Amaç | Hedef Metrik |
| :--- | :--- | :--- |
| [`01_index_health_and_waste_detector.sql`](./01_index_health_and_waste_detector.sql) | İndeks fragmantasyonu ve hiç okunmayan çöp indekslerin tespiti | I/O Tasarrufu & Rebuild Kararı |
| [`02_missing_index_impact_analyzer.sql`](./02_missing_index_impact_analyzer.sql) | Optimizer önerisi eksik indekslerin skorlanması ve DDL üretimi | Impact Score & Auto DDL |
| [`03_wait_stats_and_bottleneck_profiler.sql`](./03_wait_stats_and_bottleneck_profiler.sql) | Sunucu genelindeki Disk, CPU, Lock darboğazlarının teşhisi | Wait Stats & System Diagnosis |
| [`04_top_expensive_queries_and_cpu_hogs.sql`](./04_top_expensive_queries_and_cpu_hogs.sql) | Plan cache üzerindeki en yüksek CPU/IO harcayan sorguların tespiti | Execution Plan & Statement Extract |
| [`05_active_blocking_and_lock_tree.sql`](./05_active_blocking_and_lock_tree.sql) | Anlık kilitlenmelerde Kök Kilitleyici (Head Blocker) ve hiyerarşik kilit ağacı analizi | Head Blocker & Lock Waiting SPIDs |
| [`06_tempdb_usage_and_spill_analyzer.sql`](./06_tempdb_usage_and_spill_analyzer.sql) | TempDB sayfa tahsisleri, oturum bazlı alan kullanımı ve disk/spill darboğazları | TempDB Allocation & Internal Objects |
| [`07_memory_grants_and_buffer_cache.sql`](./07_memory_grants_and_buffer_cache.sql) | Buffer Pool (RAM) üzerindeki tablo dağılımı ve yetersiz bellek bekleme kuyruğu | RAM Usage & Memory Grant Queue |
| [`08_implicit_conversion_detector.sql`](./08_implicit_conversion_detector.sql) | Plan cache XML analizi ile Indeks Seek engelleyen örtük veri tipi dönüşümlerinin tespiti | XML Plan Warnings & Scan Prevention |