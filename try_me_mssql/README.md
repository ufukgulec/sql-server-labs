## 🩺 MSSQL Server Production Healthcheck Tools

Canlı ortamlarda (Production) kilitlenme yaratmadan, I/O dostu (`LIMITED` / `READ UNCOMMITTED`) analiz yapan senior düzey teşhis script'leri.

| Script | Amaç | Hedef Metrik |
| :--- | :--- | :--- |
| [`01_index_health_and_waste_detector.sql`](./01_index_health_and_waste_detector.sql) | İndeks fragmantasyonu ve hiç okunmayan çöp indekslerin tespiti | I/O Tasarrufu & Rebuild Kararı |
| [`02_missing_index_impact_analyzer.sql`](./02_missing_index_impact_analyzer.sql) | Optimizer önerisi eksik indekslerin skorlanması ve DDL üretimi | Impact Score & Auto DDL |
| [`03_wait_stats_and_bottleneck_profiler.sql`](./03_wait_stats_and_bottleneck_profiler.sql) | Sunucu genelindeki Disk, CPU, Lock darboğazlarının teşhisi | Wait Stats & System Diagnosis |
| [`04_top_expensive_queries_and_cpu_hogs.sql`](./04_top_expensive_queries_and_cpu_hogs.sql) | Plan cache üzerindeki en yüksek CPU/IO harcayan sorguların tespiti | Execution Plan & Statement Extract |