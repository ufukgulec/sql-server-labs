/* ===============================================================================
   Author       : Senior SQL Server DBA / Software Architect
   Description  : Execution Plan Cache verisini ayrıştırarak örtük veri tipi 
                  dönüşümü (Implicit Conversion) içeren sorguları bulur. 
                  Söz konusu sorgular indeks kullanımını (Index Seek) engeller.
   Target Engine: SQL Server 2012 ve üzeri
   =============================================================================== */

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
)
SELECT TOP 20
    cp.usecounts AS ExecutionCount,
    CAST(qp.query_plan AS XML) AS ExecutionPlan,
    st.text AS QueryText,
    CAST(p.query_plan.value('(//Warnings/PlanAffectingConvert/@Expression)[1]', 'NVARCHAR(MAX)') AS NVARCHAR(MAX)) AS ConvertExpression
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
CROSS APPLY qp.query_plan.nodes('//StmtSimple') AS n(stmt)
CROSS APPLY stmt.nodes('.//Warnings/PlanAffectingConvert') AS w(convert)
WHERE cp.cacheobjtype = 'Compiled Plan'
  AND qp.query_plan.exist('//Warnings/PlanAffectingConvert') = 1
ORDER BY cp.usecounts DESC;