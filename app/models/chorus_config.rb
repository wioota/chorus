require_relative '../../lib/shared/properties'

class ChorusConfig
  attr_accessor :config

  def initialize(root_dir=nil)
    set_root_dir(root_dir)
    app_config = {}
    app_config = Properties.load_file(config_file_path) if File.exists?(config_file_path)
    defaults = Properties.load_file(File.join(@root_dir, 'config/chorus.defaults.properties'))

    @config = ChorusConfig.deep_merge(defaults, app_config)

    secret_key_file = File.join(@root_dir, 'config/secret.key')
    abort "No config/secret.key file found.  Run rake development:init or rake development:generate_secret_key" unless File.exists?(secret_key_file)
    @config['secret_key'] = File.read(secret_key_file).strip
  end

  def [](key_string)
    keys = key_string.split('.')
    keys.inject(@config) do |hash, key|
      hash.fetch(key)
    end
  rescue IndexError
    nil
  end

  def hdfs_versions
    @available_hdfs_versions ||= initialize_hdfs_versions
  end

  def time_zones
    us_zones = ActiveSupport::TimeZone.us_zones
    other_zones = ActiveSupport::TimeZone.all.reject { |z| us_zones.include?(z) }
    us_zones.map { |z| [ z.to_s, z.name ] } + [ [nil, nil] ] + other_zones.map { |z| [ z.to_s, z.name ] }
  end

  def gpfdist_configured?
    (self['gpfdist.url'] && self['gpfdist.write_port'] && self['gpfdist.read_port'] &&
        self['gpfdist.data_dir'] && self['gpfdist.ssl.enabled'] != nil)
  end

  def tableau_configured?
    !!(self['tableau.enabled'] && self['tableau.url'] && self['tableau.port'])
  end

  def gnip_configured?
    !!self['gnip.enabled']
  end

  def workflow_configured?
    !!(workflow_url.present? && workflow_enabled.present?)
  end

  def syslog_configured?
    (self['logging.syslog.enabled'] && true)
  end

  def kaggle_configured?
    return true if File.exist? Rails.root.join('demo_data', 'kaggleSearchResults.json')
    (self['kaggle.enabled'] && self['kaggle.api_key'] && true)
  end

  def oracle_configured?
    !!self['oracle.enabled'] && (File.exist? Rails.root.join('lib', 'libraries' , 'ojdbc6.jar'))
  end

  def oracle_driver_expected_but_missing?
    !!self['oracle.enabled'] && !(File.exist? Rails.root.join('lib', 'libraries', 'ojdbc6.jar'))
  end

  def self.config_file_path(root_dir=nil)
    root_dir = Rails.root unless root_dir
    File.join root_dir, 'config/chorus.properties'
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

  def log_level
    return :info unless self['logging'] && self['logging']['loglevel']

    level = self['logging']['loglevel'].to_sym

    if [:debug, :info, :warn, :error, :fatal].include? level
      level
    else
      :info
    end
  end

  def self.instance
    @instance ||= ChorusConfig.new
  end

  def server_port
    if self['ssl.enabled']
      return self['ssl_server_port']
    end

    self['server_port']
  end

  def public_url
    self['public_url']
  end

  def branding_title
    self['alpine.branded.enabled'] ? "Alpine Chorus" : "Pivotal Chorus"
  end

  def branding_favicon
    self['alpine.branded.enabled'] ? "alpine-favicon.ico" : "favicon.ico"
  end

  def branding_logo
    self['alpine.branded.enabled'] ? "alpine-logo.png" : "headertitle.png"
  end

  def workflow_url
    self['work_flow.url'] || self['workflow.url']
  end

  def workflow_enabled
    self['work_flow.enabled'] || self['workflow.enabled']
  end

  def demo_enabled?
    self['demo_mode.enabled']
  end

  def mail_configuration
    self['mail']
  end

  def smtp_configuration
    self['smtp'].symbolize_keys
  end

  private

  def initialize_hdfs_versions
    versions = []
    pivotal_versions = [
        'Greenplum HD 0.20',
        'Greenplum HD 1.1',
        'Greenplum HD 1.2',
        'Pivotal HD 1.0',
        'Pivotal HD 1.1'
    ]
    other_versions = [
        'Apache Hadoop 0.20.2',
        'Apache Hadoop 0.20.203',
        'Apache Hadoop 1.0.4',
        'Cloudera CDH4',
        'MapR'
    ]
    versions += pivotal_versions
    versions += other_versions if self['alpine.branded.enabled']
    versions.sort
  end

  def set_root_dir(root_dir)
    @root_dir = root_dir || Rails.root
  end
end