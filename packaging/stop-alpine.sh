#!/usr/bin/env bash
bin=`readlink "$0"`
if [ "$bin" == "" ]; then
 bin=$0
fi
bin=`dirname "$bin"`
bin=`cd "$bin"; pwd`

. "$bin"/chorus-config.sh

ALPINE_PID_FILE="$ALPINE_HOME"/alpine.pid

log "stopping alpine"
CATALINA_PID=$ALPINE_PID_FILE $ALPINE_HOME/shutdown_without_database.sh