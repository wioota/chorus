require "tempfile"
require 'digest/md5'
require 'yaml'

module InstanceIntegration
  config_file = "test_instance_connection_config.yml"

  REAL_GPDB_HOST = ENV['GPDB_HOST']
  REAL_HADOOP_HOST = ENV['HADOOP_HOST']
  CONFIG = YAML.load_file(Rails.root + "config/#{config_file}")
  INSTANCE_CONFIG = CONFIG['instances']['gpdb'].find { |hash| hash["host"] == REAL_GPDB_HOST }
  ACCOUNT_CONFIG = INSTANCE_CONFIG['account']
  REAL_GPDB_USERNAME = ACCOUNT_CONFIG['db_username']
  REAL_GPDB_PASSWORD = ACCOUNT_CONFIG['db_password']
  FILES_TO_TRACK_CHANGES_OF = %w(create_private_test_schema.sql create_test_schemas.sql drop_and_create_gpdb_databases.sql)
  GPDB_VERSIONS_FILE = (Rails.root + 'tmp/instance_integration_file_versions').to_s

  def self.real_gpdb_hostname
    if REAL_GPDB_HOST.match /^([0-9]{1,3}\.){3}[0-9]{1,3}$/
      return "local_greenplum"
    end
    REAL_GPDB_HOST.gsub("-", "_")
  end

  def self.execute_sql(sql_file, database = INSTANCE_CONFIG['maintenance_db'])
    puts "Executing SQL file: #{sql_file} on host: #{INSTANCE_CONFIG['host']}"
    sql_read = File.read(File.expand_path("../#{sql_file}", __FILE__))

    sql = sql_read.gsub('gpdb_test_database', InstanceIntegration.database_name)

    database_string = "jdbc:postgresql://#{INSTANCE_CONFIG['host']}:#{INSTANCE_CONFIG['port']}/#{database}?user=#{ACCOUNT_CONFIG['db_username']}&password=#{ACCOUNT_CONFIG['db_password']}"
    Sequel.connect(database_string) do |database_connection|
      database_connection.run(sql)
    end
    return true
  rescue Exception => e
    puts e.message
    return false
  end

  def self.exec_sql_line(sql)
    conn = ActiveRecord::Base.postgresql_connection(
        :host => INSTANCE_CONFIG['host'],
        :port => INSTANCE_CONFIG['port'],
        :database => self.database_name,
        :username => ACCOUNT_CONFIG['db_username'],
        :password => ACCOUNT_CONFIG['db_password'],
        :adapter => "jdbcpostgresql")
    conn.exec_query(sql)
  end

  def self.setup_gpdb
    if gpdb_changed?
      puts "  Importing into #{InstanceIntegration.database_name}"
      execute_sql("drop_and_create_gpdb_databases.sql")
      execute_sql("create_test_schemas.sql", database_name)
      execute_sql("create_private_test_schema.sql", "#{database_name}_priv")
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
    Pathname.new(GPDB_VERSIONS_FILE + "_#{Rails.env}.yml")
  end

  def self.sql_file_hash(file_name)
    full_path = File.expand_path("../#{file_name}",  __FILE__)
    Digest::MD5.hexdigest(File.read(full_path))
  end

  def self.database_name
    "gpdb_#{Socket.gethostname}_#{Rails.env}".slice(0, 26) # needs to fit in 31 characters with _priv appended
  end

  def self.instance_config_for_gpdb(name)
    config = CONFIG['instances']['gpdb'].find { |hash| hash["host"] == name }
    config.reject { |k, v| k == "account" }
  end

  def self.instance_config_for_hadoop(name = REAL_HADOOP_HOST)
    CONFIG['instances']['hadoop'].find { |hash| hash["host"] == name }
  end

  def self.account_config_for_gpdb(name)
    config = CONFIG['instances']['gpdb'].find { |hash| hash["host"] == name }
    config["account"]
  end

  def self.refresh_chorus
    InstanceIntegration.setup_gpdb

    account = InstanceIntegration.real_gpdb_account
    GpdbDatabase.refresh(account)

    database = GpdbDatabase.find_by_name(InstanceIntegration.database_name)
    GpdbSchema.refresh(account, database)
    gpdb_schema = database.schemas.find_by_name('test_schema')
    Dataset.refresh(account, gpdb_schema)

    database_without_public_schema = GpdbDatabase.find_by_name("#{InstanceIntegration.database_name}_priv")
    GpdbSchema.refresh(account, database_without_public_schema)
    gpdb_schema_without_public_schema = database_without_public_schema.schemas.find_by_name('non_public_schema')
    Dataset.refresh(account, gpdb_schema_without_public_schema)

    account
  end

  def refresh_chorus
    InstanceIntegration.refresh_chorus
  end

  def self.real_gpdb_account
    gpdb_instance = InstanceIntegration.real_gpdb_instance
    gpdb_instance.owner_account
  end

  def self.real_gpdb_instance
    GpdbInstance.find_by_name(real_gpdb_hostname)
  end

  def self.real_database
    real_gpdb_instance.databases.find_by_name!(self.database_name)
  end
end

