export JRUBY_OPTS="--client -J-Xmx512m -J-Xms512m -J-Xmn128m -Xcext.enabled=true"
export PATH="$HOME/phantomjs/bin:$HOME/.rbenv/bin:$PATH"

eval "$(rbenv init - --no-rehash)"
rbenv shell `cat .rbenv-version`
export JASMINE_PORT=9999

gem list bundler | grep bundler || gem install bundler
bundle install --binstubs=b/ || (echo "bundler failed!!!!!!!!" && exit 1)

mkdir -p tmp/pids
rm -f tmp/fixture_builder*.yml tmp/instance_integration_file_versions*.yml tmp/GPDB_HOST_STALE

cp config/chorus.properties.example config/chorus.properties

rm -f postgres && ln -s /usr/pgsql-9.2 postgres

mkdir -p $WORKSPACE/lib/libraries
cp ~/ojdbc6.jar $WORKSPACE/lib/libraries/ojdbc6.jar

b/rake development:generate_database_yml development:generate_secret_token development:generate_secret_key db:drop db:create db:migrate --trace > "$WORKSPACE/bundle.log"