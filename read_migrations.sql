\set m_json `cat spec.json`
-- TODO: define spec path as parameter
truncate migrations.edges;

with t1  as (
     select *
     from
     rows from (jsonb_to_recordset(:'m_json'::jsonb)
		as (target text, source text, sql_path text) )
	with ordinality 

), t2 as (
     select target,
     	    coalesce(
			source,
			max(target) over w1
		)as source,
	    "sql_path"
     from t1
     window w1 as (order by ordinality
     	       	  rows between 1 preceding and current row
		  exclude current row)
)
insert into migrations.edges (select * from t2) 
