#!/bin/bash

if [ $# -eq 0 ] ; then
    echo 'USAGE: chorus_migrate.sh PATH/TO/CHORUS21_DUMP.sql'
    exit 0
fi

database=$2
[[ -z "$database" ]] && database=production

tmp_database="chorus_tmp_migrate_$RAILS_ENV"

dropdb -p 8543 $tmp_database
psql -p 8543 $database -c 'drop schema if exists legacy_migrate cascade' 2> /dev/null

# Create a temporary database so we can namespace legacy tables into their own schema
createdb -p 8543 $tmp_database
psql -p 8543 $tmp_database < $1 > /dev/null
psql -p 8543 $tmp_database -c 'alter schema public rename to legacy_migrate' > /dev/null

# Pipe the output of pg_dump into the chorus_rails db, namespaced under legacy_migrate
pg_dump --ignore-version -p 8543 $tmp_database | psql -p 8543 $database > /dev/null