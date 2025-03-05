\ir show.sql
\getenv target TARGET
\getenv schema SCHEMA

\getenv sql_dir PSQL_MIGRATE_SQL_DIR


-- set control variables
SELECT :'source' = :'target' AS finished \gset

SELECT EXISTS (SELECT FROM migrations.graph(:'schema',:'source',:'target')) AS there_is_path \gset

\if :finished
  \echo Finished!
\elif :there_is_path
  BEGIN;
  SELECT graph[2].state next_state FROM migrations.graph(:'schema',:'source',:'target') LIMIT 1 \gset
  SELECT script_name FROM migrations.edges WHERE source=:'source' AND target=:'next_state' and schema=:'schema' \gset

  \setenv NEW_STATE :'next_state'
  \setenv SQL_PATH :'script_name'

  -- \echo >>>Run :script_name
  -- \ir :script_name
  -- \set script_content `cat :script_name`
  -- INSERT INTO ddlog.ddlog(module, new_state, sql, success)  VALUES (:'schema',:'next_state',:'script_content',true);
  COMMIT;
  \ir apply-migrations.sql
\else
  \echo There is no migration path from :source to :target
\endif
