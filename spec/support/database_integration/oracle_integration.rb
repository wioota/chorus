require "tempfile"
require 'digest/md5'
require 'yaml'
require 'socket'

module OracleIntegration
  def self.hostname
    ENV['ORACLE_HOST']
  end

  def self.username
    account['db_username']
  end

  def self.password
    account['db_password']
  end

  def self.port
    oracle_config['port']
  end

  def self.db_name
    oracle_config['db_name']
  end

  def self.schema_name
    oracle_config['schema_name']
  end

  def self.real_data_source
    OracleDataSource.find_by_host(hostname)
  end

  def self.real_schema
    real_data_source.schemas.find_by_name(schema_name)
  end

  private

  def self.config
    config_file = "test_instance_connection_config.yml"
    @@config ||= YAML.load_file(File.join(File.dirname(__FILE__), '../../..', "spec/support/#{config_file}"))
  end

  def self.oracle_config
    @@oracle_config ||= find_oracle_data_source hostname
  end

  def self.find_oracle_data_source(name)
    config['instances']['oracle'].find { |hash| hash["host"] == name }
  end

  def self.account
    oracle_config['account'] || {}
  end
end

