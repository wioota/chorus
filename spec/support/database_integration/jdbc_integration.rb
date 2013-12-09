require 'tempfile'
require 'digest/md5'
require 'yaml'
require 'socket'

module JdbcIntegration

  def self.hostname
    ENV['JDBC_HOST']
  end

  def self.username
    account['db_username']
  end

  def self.password
    account['db_password']
  end

  def self.schema_name
    "test_#{Socket.gethostname.gsub('.', '_').slice(0,14)}_#{Rails.env}".slice(0,30).upcase
  end

  def self.real_data_source
    JdbcDataSource.find_by_host(hostname)
  end

  def self.connection
    JdbcConnection.new(real_data_source, real_account, {})
  end

  def self.real_account
    real_data_source.owner_account
  end

  def self.real_schema
    real_data_source.schemas.find_by_name(schema_name)
  end

  def self.setup_test_schemas
    return if schema_exists?
    puts "Importing into #{schema_name}"
    sql = ERB.new(File.read(Rails.root.join 'spec/support/database_integration/setup_jdbc_databases.sql.erb')).result(binding)
    puts 'Executing setup_jdbc_databases.sql'
    execute_sql(sql)
  end

  def self.schema_exists?
    connection.schemas.include? schema_name.downcase.to_sym
  end

  def self.execute_sql(sql)
    connection.execute(sql)
  end

  private

  def self.config
    config_file = 'test_data_sources_config.yml'
    @@config ||= YAML.load_file(File.join(File.dirname(__FILE__), '../../..', "spec/support/#{config_file}"))
  end

  def self.jdbc_config
    @@jdbc_config ||= find_jdbc_data_source hostname
  end

  def self.find_jdbc_data_source(name)
    config['data_sources']['jdbc'].find { |hash| hash['host'] == name }
  end

  def self.account
    jdbc_config['account'] || {}
  end
end