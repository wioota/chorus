require 'securerandom'
require 'pathname'

namespace :development do
  desc "Generate config/secret.token which is used for signing cookies"
  task :generate_secret_token => :ensure_chorus_home_set do
    secret_token_file = Pathname.new(ENV["CHORUS_HOME"]).join("config/secret.token")
    secret_token_file.open("w") { |f| f << SecureRandom.hex(64) } unless secret_token_file.exist?
  end

  desc "Generate config/secret.key which is used for encrypting saved database passwords"
  task :generate_secret_key => :ensure_chorus_home_set do
    secret_key_file = Pathname.new(ENV["CHORUS_HOME"]).join("config/secret.key")
    next if secret_key_file.exist?

    passphrase = Random.new.bytes(32)
    secret_key = Base64.strict_encode64(OpenSSL::Digest.new("SHA-256", passphrase).digest)
    secret_key_file.open("w") { |f| f << secret_key }
  end

  desc "Initialize the database and create the database user used by Chorus"
  task :init_database => :ensure_chorus_home_set do
    next if Pathname.new(ENV["CHORUS_HOME"]).join("postgres-db").exist?
    `DYLD_LIBRARY_PATH=$CHORUS_HOME/postgres/lib LD_LIBRARY_PATH=$CHORUS_HOME/postgres/lib $CHORUS_HOME/postgres/bin/initdb -D $CHORUS_HOME/postgres-db -E utf8`
    `$CHORUS_HOME/packaging/chorus_control.sh start postgres`
    `DYLD_LIBRARY_PATH=$CHORUS_HOME/postgres/lib LD_LIBRARY_PATH=$CHORUS_HOME/postgres/lib $CHORUS_HOME/postgres/bin/createuser -hlocalhost -p 8543 -sdr postgres_chorus`
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke
    `$CHORUS_HOME/packaging/chorus_control.sh stop postgres`
  end

  desc "Initialize development environment.  Includes initializing the database and creating secret tokens"
  task :init => [:generate_secret_token, :generate_secret_key, :init_database]


  task :ensure_chorus_home_set do
    abort("CHORUS_HOME must be set to the project root") unless ENV["CHORUS_HOME"]
  end
end