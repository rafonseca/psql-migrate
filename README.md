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
NEW_STATE=v0.99.0 SQL_PATH=fix_schema_again.sql apply-adhoc-migration.sh service=target_db 
```

### Set of migration scripts
In ad-hoc mode, the user directly determines the migration flow by choosing which script to run. A proper migration tool provides a mechanism to run a set of migration scripts. Here, this feature is designed to manage different databases each one with possibly a different current state. The idea is that the same code, when ran in different databases, will bring all them to the same target state.

Since the state is a concept defined by the user and not inferred from actual database schema, this tool gives margin to have actually different schemas across databases under the same state. This flexibility means potential inconsistency. So, if you are looking for absolute consistency across all databases note that this tool alone does not provides that.

In order to apply a set of migrations in possibly different environments, we need to define which migration scripts should run and their order. There are many ways to achieve that. Here, we use a graph where the nodes are states and the migration scripts are the edges. The current state is fetched from the respective database by consulting ddlog table. 

The target state is defined as an environment variable or it is inferred whenever possible. We support multiple independent modules. The graph itself is defined in a set of YAML files, one for each module. By default, we choose to have one schema for each module. The name of the schema/module is inferred from the yaml file name.


``` bash
SCHEMA=public TARGET=v0.99.0 apply-migrations.sh service=target_db 
```

### Managing multiple modules
...

### Setup for complex migrations
The apply-migrations script uses auxiliary tables in schema `migrations` and so, it requires some setup. We use the apply-adhoc-migration script to initialize the schema migrations using the `init.sql` script as follows:
``` bash
SCHEMA=migrations NEW_STATE=init SQL_PATH=init.sql apply-adhoc-migration.sh service=target_db 
```


### Environment

- PSQL_MIGRATE_SQL_DIR=sql
- PSQL_MIGRATE_SPECS_DIR=sql/specs

## TODO

- [ ] Implement/refactor script to run graph defined migrations

