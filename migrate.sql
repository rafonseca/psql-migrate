-- configure psql to interrupt script if any comamand fails
\set ON_ERROR_STOP on

-- create migration tables if not already present
create schema if not exists migrations;
create table if not exists migrations.log
(
  state text primary key,
  success bool default true,
  created_at timestamptz default  now()
);

-- insert special initial state if not already present
insert into migrations.log values('init') on conflict (state) do nothing;

-- create type state
-- this is only used to access the field of an anonymous record (postgres bug)
create table if not exists state (state text);


-- create temporary edges table and ingest csv
drop table if exists edges cascade;
create temp table edges (
  source text,
  target text,
  script_name text
  );
\copy edges from dependencies.csv with  csv;
update edges set source = trim(source),
                 target = trim(target),
		 script_name = trim(script_name);
table edges;		 

-- assert all scripts exist
select distinct format('\set  file_name %s \if `test -f :file_name && echo t || echo f` \echo :file_name exists \else \echo :file_name does not exists \set file_not_found t \endif',script_name) from edges \g (tuples_only) temp_file_check.sql
\set file_not_found f
\i temp_file_check.sql
\if :file_not_found
STOP. one or more files were not found
\endif
\! rm temp_file_check.sql

-- pick target state from file
\set target `cat default_target`
\echo Target State: :target

-- pick current state from db
select state as source from migrations.log where success order by created_at desc limit 1 \gset
\echo Current State: :source


-- view that generates all paths from current state to target state
drop view if exists graph;
create temp view graph as(
with recursive graph(node) as (
  select :'source'
  union
  select edges.target from graph join edges on  graph.node=edges.source
  ) cycle node set  is_cycle using path
  select node, path::text::state[] from graph where node=:'target' order by cardinality(path) 
);

-- show path
\echo path:
select path from graph limit 1;

-- set control variables 
select :'source' = :'target' as finished \gset
select exists (select from graph) as there_is_path \gset

\if :finished
  \echo Finished!
\elif :there_is_path
  begin;
   select path[2].state next_state from graph  limit 1 \gset
   select script_name from edges where source=:'source' and target=:'next_state' \gset
   \ir :script_name
   insert into migrations.log values(:'next_state');
  commit;
  \ir migrate.sql
\else
  \echo There is no migration path from :source to :target
\endif
  
