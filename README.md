# psql-migrate
psql script for managing complex and simple migrations in postgresql


## Usage
### Ad-hoc migration script
This is used to run a chosen migration script updating ddlog accordingly. We use a psql script (apply-adhoc-migration.sql) to run another psql script, the migration itself. The path to the migration script and the name of the new state (in ddlog) should be stated as the environment variables: NEW_STATE and SQL_PATH. For example:

``` bash
NEW_STATE=v0.99.0 SQL_PATH=fix_schema_again.sql psql service=target_db -f apply-adhoc-migration.sql
```
Or using a small wrapper:
``` bash
NEW_STATE=v0.99.0 SQL_PATH=fix_schema_again.sql apply-adhoc-migration service=target_db 
```


## TODO

- [x] Define common Data Definition Log schema
- [x] Implement script to run ad-hoc migration populating ddlog.sql schema

- [x] Rewrite docs and refactor code to use ddlog.sql

- [x] Define alternatives for defaut_target definition

- [ ] Implement/refactor script to run graph defined migrations

- [ ] Provide bash functions as wrappers
