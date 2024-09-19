-- configure psql to interrupt script if any comamand fails
\set ON_ERROR_STOP on

-- create migration tables if not already present
CREATE SCHEMA IF NOT EXISTS migrations;

CREATE TABLE IF NOT EXISTS migrations.log (
    state text PRIMARY KEY,
    success bool DEFAULT TRUE,
    created_at timestamptz DEFAULT now()
);

-- create type state
-- this is only used to access the field of an anonymous record (postgres bug)
CREATE TABLE IF NOT EXISTS migrations.state (
    state text
);


-- insert special initial state if not already present
INSERT INTO migrations.log
    VALUES ('init')
ON CONFLICT (state)
    DO NOTHING;

-- create temporary edges table and ingest csv
CREATE  TABLE IF NOT EXISTS migrations.edges (
    source text,
    target text,
    script_name text
);


-- function that generates all paths from current state to target state
CREATE OR REPLACE FUNCTION migrations.graph (source text, target text) returns setof migrations.state[]
LANGUAGE sql BEGIN ATOMIC;
WITH RECURSIVE graph (
    node
) AS (
    SELECT
        source
    UNION
    SELECT
        migrations.edges.target
    FROM
        graph
        JOIN migrations.edges ON graph.node = migrations.edges.source)
    CYCLE node SET is_cycle USING path
SELECT
    path::text::migrations.state[]  FROM graph
    WHERE node = target
    ORDER BY cardinality(path);
END;
