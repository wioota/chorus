#!/bin/bash

export RAILS_ENV=packaging

if [ "$HOSTNAME" = chorus-ci ]; then
  export GPDB_HOST=chorus-gpdb-ci
  export ORACLE_HOST=chorus-oracle
  export HAWQ_HOST=chorus-gphd20-2
fi

. script/ci/setup.sh

echo "checking for an alpine package"
if [[ $(ls vendor/alpine/*.sh 2> /dev/null | wc -l) != "0" ]]; then
    echo "packaging with alpine"
    chmod +x vendor/alpine/*.sh
fi

# jetpack is calling jruby -S gem, but gem is a .rbenv shim (shell script) and jruby chokes
# https://github.com/jruby/jruby/issues/1218
export PATH=/var/lib/jenkins/.rbenv/versions/jruby-1.7.11/bin:$PATH

rm -fr .bundle
bundle exec rake package:installer --trace
