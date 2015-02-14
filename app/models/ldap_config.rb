require_relative '../../lib/shared/properties'
require 'set'

class LdapConfig
  attr_accessor :config

  def initialize(root_dir=nil)
    set_root_dir(root_dir)
    ldap_config = {}
    @config = Properties.load_file(config_file_path) if File.exists?(config_file_path)
  end

  def self.exists?
    File.exists?(config_file_path)
  end

  def [](key_string)
    keys = key_string.split('.')
    keys.inject(@config) do |hash, key|
      hash.fetch(key)
    end
  rescue IndexError
    nil
  end

   def with_temporary_config(new_config_hash)
     old_config = @config.deep_dup
     @config.deep_merge! new_config_hash.stringify_keys
     yield
   ensure
     @config = old_config
   end

  def self.config_file_path(root_dir=nil)
    root_dir = Rails.root unless root_dir
    File.join root_dir, 'config/ldap.properties'
  end

  def config_file_path
    self.class.config_file_path(@root_dir)
  end

  def self.deep_merge(hash, other_hash)
    deep_merge!(hash.dup, other_hash)
  end

  def self.deep_merge!(hash, other_hash)
    other_hash.each_pair do |k,v|
      tv = hash[k]
      hash[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? deep_merge(tv, v) : v
    end
    hash
  end

  def self.instance
    @instance ||= LdapConfig.new
  end

  private

  def set_root_dir(root_dir)
    @root_dir = root_dir || Rails.root
  end
end
