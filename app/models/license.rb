require 'honor_codes/core'

class License
  attr_accessor :license
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

  private

  def license_path
    Rails.root.join 'config', 'chorus.license'
  end

  def default_license_path
    Rails.root.join 'config', 'chorus.license.default'
  end
end
