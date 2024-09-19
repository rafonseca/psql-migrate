-- configure psql to interrupt script if any comamand fails
\set ON_ERROR_STOP on


TRUNCATE TABLE migrations.edges;

\copy migrations.edges from dependencies.csv with csv header;

-- assert all scripts exist
SELECT DISTINCT
    format('\set  file_name %s \if `test -f :file_name && echo t || echo f` \echo >> :file_name exists \else \echo >> :file_name does not exists \set file_not_found t \endif', script_name)
FROM
    migrations.edges \g (tuples_only) temp_file_check.sql

\set file_not_found f
\i temp_file_check.sql
\if :file_not_found
SELECT
    raise_error;

\endif
\! rm temp_file_check.sql
