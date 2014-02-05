require 'honor_codes/core'

class License
  OPEN_CHORUS = 'openchorus'

  def initialize
    path = (File.exists?(license_path) ? license_path : default_license_path)
    @license = HonorCodes.interpret(path)[:license].symbolize_keys
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
    Rails.root.join 'config', 'chorus.license'
  end

  def default_license_path
    Rails.root.join 'config', 'chorus.license.default'
  end
end
