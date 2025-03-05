-- configure psql to interrupt script if any comamand fails
\set ON_ERROR_STOP on

\echo Importing spec.json
TRUNCATE TABLE migrations.edges;
\ir read_migrations.sql

-- pick target state from file
\echo Setting target
\set target `cat default_target`
\echo Target State: :target

\echo Setting source
-- pick current state from db
SELECT
    state AS source
FROM
    migrations.log
WHERE
    success
ORDER BY
    created_at DESC
LIMIT 1 \gset

\echo Current State: :source

-- show path
\echo path:
SELECT graph as path FROM migrations.graph(:'source',:'target') LIMIT 1;
