--http://mssqlwiki.com/2012/10/04/troubleshooting-sql-server-high-cpu-usage/
/*
1. Query execution causing CPU spike:
Query execution  takes long times and spikes CPU commonly because 
of in-correct cardinality estimates caused by outdated statistics, 
Lack of Index, Server configuration, Distributed queries, etc.
When the server is experiencing this problem run the query in below 
link to list all the queries which are executing in the server order 
by CPU time desc along with plan.
*/


SELECT getdate() as "RunTime", st.text, qp.query_plan, a.* 
FROM sys.dm_exec_requests a 
CROSS APPLY sys.dm_exec_sql_text(a.sql_handle) as st 
CROSS APPLY sys.dm_exec_query_plan(a.plan_handle) as qp order by CPU_time desc

