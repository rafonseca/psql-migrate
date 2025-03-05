-- configure psql to interrupt script if any comamand fails
\set ON_ERROR_STOP on
\getenv schema SCHEMA


\echo Importing spec.json
TRUNCATE TABLE migrations.edges;
\ir read_migrations.sql


\echo Setting source
-- pick current state from db
SELECT
    state AS source
FROM
    ddlog.ddlog
WHERE
    success and module=:'schema'
ORDER BY
    applied_at DESC
LIMIT 1 \gset

\echo Current State: :source

-- show path
\echo path:
SELECT graph as path FROM migrations.graph(:'source',:'target') LIMIT 1;
