#!/bin/bash

export RAILS_ENV=test
GPDB_HOST=chorus-gpdb42
HADOOP_HOST=chorus-gphd02

. script/ci/setup.sh

set -e

targets=${@}

run_jasmine=true
run_ruby=true
run_legacy_migrations=true
run_api_docs= true
if [[ -nz "$targets" ]]; then
    run_jasmine=false
    run_ruby=false
    run_legacy_migrations=false
    run_api_docs=false
    for target in "$targets"; do
        if [[ "$target" == "jasmine" ]] ; then
           run_jasmine=true
        fi
        if [[ "$target" == "backend" ]] ; then
           run_ruby=true
        fi
        if [[ "$target" == "legacy_migrations" ]] ; then
           run_legacy_migrations=true
        fi
        if [[ "$target" == "api_docs" ]] ; then
           run_api_docs=true
        fi
    done
fi

if $run_ruby; then
   b/rake assets:precompile --trace

    echo "starting gpfdist (Linux RHEL5 only)"
    export LD_LIBRARY_PATH=vendor/gpfdist-rhel5/lib:${LD_LIBRARY_PATH}
    ./vendor/gpfdist-rhel5/bin/gpfdist -p 8000 -d /tmp &
    ./vendor/gpfdist-rhel5/bin/gpfdist -p 8001 -d /tmp &
fi

# start jasmine
if $run_jasmine ; then
    b/rake jasmine > $WORKSPACE/jasmine.log 2>&1 &
    jasmine_pid=$!
    echo "Jasmine process id is : $jasmine_pid"
    echo $jasmine_pid > tmp/pids/jasmine-$RAILS_ENV.pid

    sleep 30
fi

set +e

unset RAILS_ENV

if $run_ruby ; then
    echo "Running unit tests"
    mv .rspec-ci .rspec
    GPDB_HOST=$GPDB_HOST HADOOP_HOST=$HADOOP_HOST b/rake -f `bundle show ci_reporter`/stub.rake ci:setup:rspec spec 2>&1
    RUBY_TESTS_RESULT=$?
else
    RUBY_TESTS_RESULT=0
fi

if $run_jasmine ; then
    echo "Running javascript tests"
    CI_REPORTS=spec/javascripts/reports b/rake -f `bundle show ci_reporter`/stub.rake ci:setup:rspec phantom 2>&1
    JS_TESTS_RESULT=$?

    echo "Cleaning up jasmine process $jasmine_pid"
    kill -s SIGTERM $jasmine_pid
else
    JS_TESTS_RESULT=0
fi

if $run_ruby ; then
    echo "Cleaning up gpfdist"
    killall gpfdist
fi

if $run_legacy_migrations; then
    echo "Running legacy migration tests"
    b/rake db:test:prepare
    CI_REPORTS=spec/legacy_migration/reports b/rake -f `bundle show ci_reporter`/stub.rake ci:setup:rspec spec:legacy_migration
    LEGACY_MIGRATION_TESTS_RESULT=$?
else
    LEGACY_MIGRATION_TESTS_RESULT=0
end

if $run_api_docs ; then
    echo "Running API docs check"
    b/rake api_docs:check
    API_DOCS_CHECK_RESULT=$?
else
    API_DOCS_CHECK_RESULT=0
fi

if $run_ruby ; then
  echo "RSpec exit code: $RUBY_TESTS_RESULT"
end

if $run_jasmine ; then
    echo "Jasmine exit code: $JS_TESTS_RESULT"
fi

if $run_legacy_migrations ; then
  echo "Legacy migration exit code: $LEGACY_MIGRATION_TESTS_RESULT"
end

if $run_api_docs ; then
  echo "API docs check exit code: $API_DOCS_CHECK_RESULT"
end

SUCCESS=`expr $RUBY_TESTS_RESULT + $JS_TESTS_RESULT + $LEGACY_MIGRATION_TESTS_RESULT + $API_DOCS_CHECK_RESULT`
exit $SUCCESS
