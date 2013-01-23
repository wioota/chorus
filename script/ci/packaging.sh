#!/bin/bash

export RAILS_ENV=packaging
GPDB_HOST=chorus-gpdb42
ORACLE_HOST=chorus-oracle

. script/ci/setup.sh

rm -fr .bundle
GPDB_HOST=$GPDB_HOST ORACLE_HOST=$ORACLE_HOST bundle exec rake package:installer --trace
