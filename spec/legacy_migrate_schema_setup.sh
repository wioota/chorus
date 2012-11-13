#!/bin/bash

if [ $# -eq 0 ] ; then
    echo 'USAGE: $0 <PATH/TO/CHORUS21_DUMP.sql> <database_name>'
    exit 0
fi

sql=$1
database=$2
[[ -z "$database" ]] && database=chorus_rails_test

tmp_database="chorus_tmp_migrate_$RAILS_ENV"

dropdb -p 8543 $tmp_database 2>&1
psql -p 8543 $database -c 'drop schema if exists legacy_migrate cascade' 2>&1

# TODO: why do we do this twice?
dropdb -p 8543 $tmp_database 2> /dev/null
psql -p 8543 $database -c 'drop schema if exists legacy_migrate cascade' 2> /dev/null
# Create a temporary database so we can namespace legacy tables into their own schema
createdb -p 8543 $tmp_database 2>&1
psql -p 8543 $tmp_database -f $sql 2>&1
psql -p 8543 $tmp_database -c 'alter schema public rename to legacy_migrate' 2>&1

# Pipe the output of pg_dump into the chorus_rails db, namespaced under legacy_migrate
(pg_dump --ignore-version -p 8543 $tmp_database | psql -p 8543 $database) 2>&1
