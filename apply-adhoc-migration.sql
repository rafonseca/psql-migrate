\set ON_ERROR_STOP on
\getenv new_state NEW_STATE
\getenv sql_path SQL_PATH

\if :{?new_state}
  \if :{?sql_path}
    begin;
    \qecho executing :sql_path
    \i :sql_path

    -- create entry in ddlog using \copy. then, set success=true
    \set sql_script `cat $SQL_PATH`
    insert into ddlog.ddlog(sql) values (:'sql_script');

    -- we can use now() as a filter because statements are in same transaction

    update ddlog.ddlog set 
      success=true,
      new_state=nullif(:'new_state','')
      where applied_at=now();
    commit;
  \else
    \echo 'error: should set environment variable SQL_PATH'
  \endif
\else
  \echo 'error: should set environment variable NEW_STATE'
\endif
