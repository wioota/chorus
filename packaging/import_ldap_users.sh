#!/bin/sh
bin=`readlink "$0"`
if [ "$bin" == "" ]; then
 bin=$0
fi
bin=`dirname "$bin"`
bin=`cd "$bin"; pwd`

. "$bin"/chorus-config.sh

$CHORUS_HOME/postgres/bin/pg_ctl -D ./postgres-db  status | grep "is running"  > /dev/null

if [ "$?" != 0 ]; then
    echo "Chorus must be running before importing LDAP users. Please start Chorus and try again."
    exit 1
fi

echo "Importing LDAP users to CHorus"
echo "==============================\n"
bundle exec rake ldap:import_users
exit 0

