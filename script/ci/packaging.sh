#!/bin/bash

export RAILS_ENV=packaging

if [ "$HOSTNAME" = chorus-ci ]; then
  export GPDB_HOST=chorus-gpdb-ci
  export ORACLE_HOST=chorus-oracle
  export HAWQ_HOST=chorus-gphd20-2
fi

. script/ci/setup.sh

if [[ $ALPINE_ZIP ]]; then
    (mkdir -p vendor/alpine; cd vendor/alpine; wget --quiet $ALPINE_ZIP)
fi

rm -fr .bundle
bundle exec rake package:installer --trace
