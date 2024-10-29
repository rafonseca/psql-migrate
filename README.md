# psql-migrate
psql script for managing complex migrations in postgres

## Features
- No extra dependencies. No need to install Maven, Ruby, CPAN, etc.
- Graph based migrations for maximum flexibility.
- No implicit revert. (Yes, I consider it a feature)
- Applied migrations are fully logged in the DB.
- Migration scripts are graph *edges* while desired DB states are graph *nodes*.
- Possible reuse of migration scripts across projects.
- Multiple migration paths allow to manage inconsistent multi-tenant projects. 

## Installation

Copy the file `migrate.sql` to `migration/` folder inside your project. 

## Usage

In the same folder of `migrate.sql`, put the following files: `dependencies.csv` and `default_target`. 

### dependencies.csv

It is a three column csv  with headers. It describes the graphs of migrations where the edges are the migration scripts. The first two columns are *source* and *target* states and can be arbitrary strings (excluding comma of course). By default, the initial state is `init`. So the first migration to run should be of the form:

``` csv
source,target,script_name
init,my first state,some_script.sql
```


The order of the entries in the file does not matter.

### default_target

It is a simple text file containing the target state. The content of this file should match the second column of at least one of the rows in dependencies.

### Run!

``` shell
cd migrations
psql -i migrate.sql [psql connection params]
```

### Inspect
The table `log` in schema `migrations` is created if does not exists and it stores the applied migrations

``` sql
select * from migrations.log;
```

The current state is inferred from this same table

``` sql
select state from migrations.log order by created_at desc limit 1;
```

The graph described in `dependencies.csv` does not persist on the DB.

## TODO

- [x] Define common Data Definition Log schema

- [ ] Implement script to run ad-hoc migration populating ddlog.sql schema

- [ ] Rewrite docs and refactor code to use ddlog.sql

- [ ] Improve docs/Create example

- [ ] Define alternatives for defaut_target definition
