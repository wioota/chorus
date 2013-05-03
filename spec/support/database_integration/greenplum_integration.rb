require "tempfile"
require 'digest/md5'
require 'yaml'
require 'socket'

module GreenplumIntegration
  FILES_TO_TRACK_CHANGES_OF = Dir[*%w{(
    greenplum_integration.rb
    create_users.sql.erb
    drop_and_create_gpdb_databases.sql.erb
    create_test_schemas.sql.erb
    create_private_test_schema.sql.erb
    create_test_schemas.sql.erb
    drop_public_schema.sql.erb
  }]
  VERSIONS_FILE = (File.join(File.dirname(__FILE__), '../../..', 'tmp/data_source_integration_file_versions')).to_s

  def self.execute_sql(sql_file, database = greenplum_config['db_name'])
    puts "Executing SQL file: #{sql_file} on host: #{hostname}"
    sql_erb = ERB.new(File.read(File.expand_path("../#{sql_file}.erb", __FILE__)))

    sql = sql_erb.result(binding)

    database_string = "jdbc:postgresql://#{hostname}:#{port}/#{database}"
    Sequel.connect(database_string, :user => username, :password => password) do |database_connection|
      database_connection.run(sql)
    end
    return true
  rescue Exception => e
    puts e.message
    return false
  end

  def self.exec_sql_line(sql)
    conn = ActiveRecord::Base.postgresql_connection(
        :host => hostname,
        :port => port,
        :database => self.database_name,
        :username => username,
        :password => password,
        :adapter => "jdbcpostgresql")
    conn.exec_query(sql)
  end

  def self.drop_test_db
    conn = ActiveRecord::Base.postgresql_connection(
        :host => hostname,
        :port => port,
        :database => "postgres",
        :username => username,
        :password => password,
        :adapter => "jdbcpostgresql")
    conn.exec_query("DROP DATABASE IF EXISTS \"#{GreenplumIntegration.database_name}\"")
  end

  def self.setup_gpdb
    if gpdb_changed?
      puts "  Importing into #{GreenplumIntegration.database_name}"
      drop_test_db
      execute_sql("create_users.sql")
      success = execute_sql("drop_and_create_gpdb_databases.sql")
      success &&= execute_sql("create_test_schemas.sql", database_name)
      success &&= execute_sql("create_private_test_schema.sql", "#{database_name}_priv")
      success &&= execute_sql("create_test_schemas.sql", "#{database_name}_wo_pub")
      success &&= execute_sql("drop_public_schema.sql", "#{database_name}_wo_pub")
      raise "Unable to add test data to #{GreenplumIntegration.hostname}" unless success
      record_changes
    end
  end

  def self.record_changes
    results_hash = FILES_TO_TRACK_CHANGES_OF.inject({}) do |hash, file_name|
      hash[file_name] = sql_file_hash(file_name)
      hash
    end
    results_hash["GPDB_HOST"] = ENV['GPDB_HOST']
    gpdb_versions_file.open('w') do |f|
      YAML.dump(results_hash, f)
    end
  end

  def self.gpdb_changed?
    versions = gpdb_versions_hash
    FILES_TO_TRACK_CHANGES_OF.any? do |file_name|
      versions[file_name.to_s] != sql_file_hash(file_name)
    end || versions["GPDB_HOST"] != ENV['GPDB_HOST']
  end

  def self.gpdb_versions_hash
    return {} unless gpdb_versions_file.exist?
    YAML.load_file(gpdb_versions_file.to_s)
  end

  def self.gpdb_versions_file
    Pathname.new(VERSIONS_FILE + "_#{ENV['RAILS_ENV']}.yml")
  end

  def self.sql_file_hash(file_name)
    full_path = File.expand_path("../#{file_name}",  __FILE__)
    Digest::MD5.hexdigest(File.read(full_path))
  end

  def self.database_name
    "gpdb_#{Socket.gethostname.gsub('.', '_')}_#{ENV['RAILS_ENV']}".slice(0, 26) # needs to fit in 31 characters with _priv appended
  end

  def self.data_source_config(name)
    config = find_greenplum_data_source name
    account_config = config['account']
    config.reject { |k, v| k == "account" }.merge(account_config)
  end

  def self.account_config(name)
    find_greenplum_data_source(name)['account']
  end

  def self.refresh_chorus
    GreenplumIntegration.setup_gpdb

    account = GreenplumIntegration.real_account
    GpdbDatabase.refresh(account)

    database = GpdbDatabase.find_by_name(GreenplumIntegration.database_name)
    GpdbSchema.refresh(account, database)
    gpdb_schema = database.schemas.find_by_name('test_schema')
    gpdb_schema.refresh_datasets(account)

    database_without_public_schema = GpdbDatabase.find_by_name("#{GreenplumIntegration.database_name}_priv")
    GpdbSchema.refresh(account, database_without_public_schema)
    gpdb_schema_without_public_schema = database_without_public_schema.schemas.find_by_name('non_public_schema')
    gpdb_schema_without_public_schema.refresh_datasets(account)

    account
  end

  def refresh_chorus
    GreenplumIntegration.refresh_chorus
  end

  def self.hostname
    ENV['GPDB_HOST']
  end

  def self.real_account
    gpdb_data_source = GreenplumIntegration.real_data_source
    gpdb_data_source.owner_account
  end

  def self.real_data_source
    #GpdbDataSource.find_by_name(hostname) works 99% of the time, but fails with a mysterious 'type IN (0)' error 1% of the time
    GpdbDataSource.find_by_sql(%Q{SELECT  "data_sources".* FROM "data_sources"  WHERE "data_sources"."name" = '#{hostname}' LIMIT 1}).first
  end

  def self.real_database
    real_data_source.databases.find_by_name!(self.database_name)
  end

  def self.username
    greenplum_account['db_username']
  end

  def self.password
    greenplum_account['db_password']
  end

  def self.port
    greenplum_config['port']
  end

  private

  def self.config
    config_file = "test_data_sources_config.yml"
    @@config ||= YAML.load_file(File.join(File.dirname(__FILE__), '../../..', "spec/support/#{config_file}"))
  end

  def self.greenplum_config
    @@gp_config ||= find_greenplum_data_source hostname
  end

  def self.find_greenplum_data_source(name)
    config['data_sources']['gpdb'].find { |hash| hash["host"] == name }
  end

  def self.greenplum_account
    greenplum_config['account'] || {}
  end
end

