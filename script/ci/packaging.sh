#!/bin/bash

export RAILS_ENV=packaging
GPDB_HOST=chorus-gpdb-ci
ORACLE_HOST=chorus-oracle
HAWQ_HOST=chorus-gphd20-2

. script/ci/setup.sh

if [[ $ALPINE_ZIP ]]; then
    (mkdir -p vendor/alpine; cd vendor/alpine; wget --quiet $ALPINE_ZIP)
fi

if [[ $PIVOTALLABEL ]]; then
    sed -i "s/alpine\.branded\.enabled\=true/alpine\.branded\.enabled\=false/" config/chorus.defaults.properties
fi

rm -fr .bundle
GPDB_HOST=$GPDB_HOST HAWQ_HOST=$HAWQ_HOST ORACLE_HOST=$ORACLE_HOST bundle exec rake package:installer --trace
