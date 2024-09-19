-- configure psql to interrupt script if any comamand fails
\set ON_ERROR_STOP on
-- create migration tables if not already present
CREATE SCHEMA IF NOT EXISTS migrations;

CREATE TABLE IF NOT EXISTS migrations.log (
    state text PRIMARY KEY,
    success bool DEFAULT TRUE,
    created_at timestamptz DEFAULT now()
);

-- insert special initial state if not already present
INSERT INTO migrations.log
    VALUES ('init')
ON CONFLICT (state)
    DO NOTHING;

-- create type state
-- this is only used to access the field of an anonymous record (postgres bug)
CREATE TABLE IF NOT EXISTS state (
    state text
);

-- create temporary edges table and ingest csv
DROP TABLE IF EXISTS edges CASCADE;

CREATE temp TABLE edges (
    source text,
    target text,
    script_name text
);

\copy edges from dependencies.csv with  csv;
UPDATE
    edges
SET
    source = trim(source),
    target = trim(target),
    script_name = trim(script_name);

TABLE edges;

-- assert all scripts exist
SELECT DISTINCT
    format('\set  file_name %s \if `test -f :file_name && echo t || echo f` \echo :file_name exists \else \echo :file_name does not exists \set file_not_found t \endif', script_name)
FROM
    edges \g (tuples_only) temp_file_check.sql

\set file_not_found f
\i temp_file_check.sql
\if :file_not_found
select raise_error;

\endif
\! rm temp_file_check.sql
-- pick target state from file
\set target `cat default_target`
\echo Target State: :target
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
-- view that generates all paths from current state to target state
DROP VIEW IF EXISTS graph;

CREATE temp VIEW graph AS (
    WITH RECURSIVE graph (
        node
) AS (
        SELECT
            :'source'
        UNION
        SELECT
            edges.target
        FROM
            graph
            JOIN edges ON graph.node = edges.source)
        CYCLE node SET is_cycle USING path
        SELECT
            node, path::text::state[] FROM graph
            WHERE
                node = :'target' ORDER BY cardinality(path));

-- show path
\echo path:
SELECT
    path
FROM
    graph
LIMIT 1;

-- set control variables
SELECT
    :'source' = :'target' AS finished \gset

SELECT
    EXISTS (
        SELECT
        FROM
            graph) AS there_is_path \gset

\if :finished
\echo Finished!
\elif :there_is_path
BEGIN;
SELECT
    path[2].state next_state
FROM
    graph
LIMIT 1 \gset
SELECT
    script_name
FROM
    edges
WHERE
    source = :'source'
    AND target = :'next_state' \gset
\ir :script_name
INSERT INTO migrations.log
    VALUES (:'next_state');
COMMIT;

\ir migrate.sql
\else
\echo There is no migration path from :source to :target
\endif
