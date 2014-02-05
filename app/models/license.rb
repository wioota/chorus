require 'honor_codes/core'

class License
  OPEN_CHORUS = 'openchorus'

  def initialize(root_dir=nil)
    # not guaranteed to have rails/active support (e.g. generate nginx conf)
    set_root_dir(root_dir)
    path = (File.exists?(license_path) ? license_path : default_license_path)
    @license = HonorCodes.interpret(path)[:license]
    symbolize_keys_of @license
  end

  def self.instance
    @instance ||= License.new
  end

  def [](key)
    @license[key]
  end

  def workflow_enabled?
    %w(alpine pivotal).include? self[:vendor]
  end

  def branding
    self[:vendor] == 'pivotal' ? 'pivotal' : 'alpine'
  end

  def branding_title
    %Q(#{self.branding.titlecase} Chorus)
  end

  private

  attr_reader :license

  def license_path
    File.join @root_dir, 'config', 'chorus.license'
  end

  def default_license_path
    File.join @root_dir, 'config', 'chorus.license.default'
  end

  def set_root_dir(root_dir)
    @root_dir = root_dir || Rails.root
  end

  def symbolize_keys_of(hash)
    hash.keys.each do |key|
      hash[(key.to_sym rescue key) || key] = hash.delete(key)
    end
  end
end
