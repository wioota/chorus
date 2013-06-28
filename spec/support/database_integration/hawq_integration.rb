module HawqIntegration
  def self.real_data_source
    #GpdbDataSource.find_by_name(hostname) works 99% of the time, but fails with a mysterious 'type IN (0)' error 1% of the time
    GpdbDataSource.find_by_sql(%Q{SELECT  "data_sources".* FROM "data_sources"  WHERE "data_sources"."name" = '#{hostname}' LIMIT 1}).first
  end

  def self.config
    config_file = "test_data_sources_config.yml"
    @@config ||= YAML.load_file(File.join(File.dirname(__FILE__), '../../..', "spec/support/#{config_file}"))
  end

  def self.data_source_config(name)
    config = find_hawq_data_source name
    account_config = config['account']
    config.reject { |k, v| k == "account" }.merge(account_config)
  end

  def self.hawq_config
    @@gp_config ||= find_hawq_data_source hostname
  end

  def self.hostname
    ENV['HAWQ_HOST']
  end

  def self.find_hawq_data_source(name)
    config['data_sources']['hawq'].find { |hash| hash["host"] == name }
  end
end