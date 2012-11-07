export JRUBY_OPTS="--1.9 --client -J-Xmx512m -J-Xms512m -J-Xmn128m"
export PATH="$HOME/phantomjs/bin:$HOME/.rbenv/bin:$PATH"

eval "$(rbenv init - --no-rehash)"
rbenv shell `cat .rbenv-version`
export JASMINE_PORT=8888

gem list bundler | grep bundler || gem install bundler
bundle install --binstubs=b/ || (echo "bundler failed!!!!!!!!" && exit 1)

mkdir -p tmp/pids
rm -f tmp/fixture_builder*.yml

cp config/chorus.properties.example config/chorus.properties

b/rake development:generate_secret_token development:generate_secret_key db:drop db:create db:migrate --trace > "$WORKSPACE/bundle.log"

# backup and restore tests need postgres to be installed in CHORUS_HOME
rm -f postgres && ln -s /usr/pgsql-9.2 postgres

