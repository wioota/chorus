require "tempfile"
require 'digest/md5'
require 'yaml'
require 'socket'

module HadoopIntegration
  HOST = ENV['HADOOP_HOST']

  def self.instance_config(name = HOST)
    config['instances']['hadoop'].find { |hash| hash["host"] == name }
  end

  private

  def self.config
    config_file = "test_instance_connection_config.yml"
    @@config ||= YAML.load_file(File.join(File.dirname(__FILE__), '../../..', "spec/support/#{config_file}"))
  end
end