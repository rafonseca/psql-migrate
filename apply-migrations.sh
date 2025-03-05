#!/usr/bin/bash
set -e
# Usually, this script is executed from the migrations dir of the
# application. So, we need to find its path to invoke respective sql
# script.

PSQL_MIGRATE_PATH=$(dirname $(realpath $BASH_SOURCE))

export PSQL_MIGRATE_SQL_DIR=${PSQL_MIGRATE_SQL_DIR:-"sql"}
export PSQL_MIGRATE_SPECS_DIR=${PSQL_MIGRATE_SPECS_DIR:-"sql/specs"}

EMSG="Environment variable must be defined"
: ${TARGET? $EMSG} # TODO: remove this restriction

export SCHEMA=${SCHEMA:-public}

PSQL_MIGRATE_PATH=$(dirname $(realpath $BASH_SOURCE))


SPEC_PATH=$PSQL_MIGRATE_SPECS_DIR/$SCHEMA
test -f $SPEC_PATH.yaml || \
    { echo "spec file not found: $SPEC_PATH.yaml" ; exit 1 ; }

# yq does no return proper exit code, so we dont check it. just hope it works...
yq -P -oj $SPEC_PATH.yaml > $SPEC_PATH.json
jq . $SPEC_PATH.json >/dev/null || \
    { echo "error in file: $SPEC_PATH.json"; exit 1 ; }


psql  $@ -f $PSQL_MIGRATE_PATH/read_migrations.sql
#psql  $@ -f $PSQL_MIGRATE_PATH/apply-migrations.sql

mv $SPEC_PATH.json $SPEC_PATH.json.old
