#!/bin/bash

export RAILS_ENV=test
GPDB_HOST=chorus-gpdb42
HADOOP_HOST=chorus-gphd02

set -v
set -e

. script/ci/setup.sh

echo "starting gpfdist (Linux RHEL5 only)"
export LD_LIBRARY_PATH=vendor/gpfdist-rhel5/lib:${LD_LIBRARY_PATH}
./vendor/gpfdist-rhel5/bin/gpfdist -p 8000 -d /tmp &
./vendor/gpfdist-rhel5/bin/gpfdist -p 8001 -d /tmp &
sleep 30

set +e

unset RAILS_ENV

echo "Running unit tests"
mv .rspec-ci .rspec
GPDB_HOST=$GPDB_HOST HADOOP_HOST=$HADOOP_HOST b/rake -f `bundle show ci_reporter`/stub.rake ci:setup:rspec spec 2>&1
RUBY_TESTS_RESULT=$?

echo "Cleaning up gpfdist"
killall gpfdist

echo "Running API docs check"
b/rake api_docs:check
API_DOCS_CHECK_RESULT=$?

SUCCESS=`expr $RUBY_TESTS_RESULT + $API_DOCS_CHECK_RESULT`
echo "RSpec exit code: $RUBY_TESTS_RESULT"
echo "API docs check exit code: $API_DOCS_CHECK_RESULT"
exit $SUCCESS
