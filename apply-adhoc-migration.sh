#!/usr/bin/bash

# Usually, this script is executed from the migrations dir of the
# application. So, we need to find its path to invoke respective sql
# script.
PSQL_MIGRATE_PATH=$(dirname $(realpath $BASH_SOURCE))


EMSG="Environment variable must be defined"
: ${NEW_STATE? $EMSG}
: ${SQL_PATH? $EMSG}

export SCHEMA=${SCHEMA:-public}


psql  $@ -f $PSQL_MIGRATE_PATH/apply-adhoc-migration.sql
