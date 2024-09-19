\ir show.sql

-- set control variables
SELECT :'source' = :'target' AS finished \gset

SELECT EXISTS (SELECT FROM migrations.graph(:'source',:'target')) AS there_is_path \gset

\if :finished
\echo Finished!
\elif :there_is_path
BEGIN;
SELECT graph[2].state next_state FROM migrations.graph(:'source',:'target') LIMIT 1 \gset
SELECT script_name FROM migrations.edges WHERE source=:'source' AND target=:'next_state' \gset
\echo >>>Run :script_name
\ir :script_name
INSERT INTO migrations.log
    VALUES (:'next_state');
COMMIT;

\ir migrate.sql
\else
\echo There is no migration path from :source to :target
\endif
