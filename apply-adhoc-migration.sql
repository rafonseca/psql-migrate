\set ON_ERROR_STOP on
\getenv new_state NEW_STATE
\getenv sql_path SQL_PATH

\if :{?new_state}
  -- TODO: handle revert migration
  select exists
  (select from ddlog.ddlog where new_state=nullif(:'new_state',''))
  as new_state_not_exists \gset
  \if :new_state_exists
    \echo 'error: new_state already exists in ddlog'
  \else  
    \if :{?sql_path}
      -- run migration and register on ddlog in same transaction
      begin;
      
      \qecho executing :sql_path
      \i :sql_path

      \set sql_script `cat $SQL_PATH`
      
      insert into ddlog.ddlog (sql,           new_state,               success)
      values                  (:'sql_script', nullif(:'new_state',''), true);

      commit;
    \else
      \echo 'error: should set environment variable SQL_PATH'
    \endif
  \endif
\else
  \echo 'error: should set environment variable NEW_STATE'
\endif
