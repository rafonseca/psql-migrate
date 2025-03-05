-- configure psql to interrupt script if any comamand fails
\set ON_ERROR_STOP on

-- create migration tables if not already present
CREATE SCHEMA IF NOT EXISTS migrations;


-- create type state
-- this is only used to access the field of an anonymous record (postgres bug)
CREATE TABLE IF NOT EXISTS migrations.state (
    state text
);

-- create  edges table 
CREATE  TABLE IF NOT EXISTS migrations.edges (
    schema text,
    source text,
    target text,
    script_path text
);


-- function that generates all paths from current state to target state
CREATE OR REPLACE FUNCTION migrations.graph ("schema" text, source text, target text) returns setof migrations.state[]
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
        JOIN migrations.edges ON graph.node = migrations.edges.source
    WHERE
	migrations.edges.schema = graph.schema)
    CYCLE node SET is_cycle USING path
SELECT
    path::text::migrations.state[]  FROM graph
    WHERE graph.node = target
    ORDER BY cardinality(path);
END;
