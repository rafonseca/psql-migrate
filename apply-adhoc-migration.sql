\set ON_ERROR_STOP on
\getenv new_state NEW_STATE
\getenv sql_path SQL_PATH
\getenv schema SCHEMA

select exists (select from ddlog.ddlog where new_state=nullif(:'new_state','') and success)
as new_state_exists \gset

\if :new_state_exists
  \echo 'ERROR: new_state already exists in ddlog'
  \quit
\else  
  -- run migration and register on ddlog in same transaction
  begin;
  -- set search path locally
  select set_config('search_path', :'schema'||','||current_setting('search_path'), true);
  \qecho executing :sql_path  
  \i :sql_path
  \set sql_script `cat $SQL_PATH`
  insert into ddlog.ddlog (module,	sql,           new_state,               success)
  values                  (:'schema',	:'sql_script', nullif(:'new_state',''), true);
  commit;
\endif

