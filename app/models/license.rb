require 'honor_codes/core'

class License
  OPEN_CHORUS = 'openchorus'
  VENDOR_ALPINE = 'alpine'
  VENDOR_PIVOTAL = 'pivotal'
  LEVEL_EXPLORER = 'explorer'
  LEVEL_BASECAMP = 'basecamp'
  LEVEL_SUMMIT = 'summit'

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
    alpine_or_pivotal?
  end

  def branding
    self[:vendor] == VENDOR_PIVOTAL ? VENDOR_PIVOTAL : VENDOR_ALPINE
  end

  def branding_title
    %(#{self.branding.titlecase} Chorus)
  end

  def full_search_enabled?
    !explorer?
  end

  def advisor_now_enabled?
    alpine_or_pivotal?
  end

  def limit_workspace_membership?
    explorer?
  end

  def limit_user_count?
    alpine_or_pivotal?
  end

  private

  attr_reader :license

  def explorer?
    self[:vendor] == VENDOR_ALPINE && self[:level] == LEVEL_EXPLORER
  end

  def alpine_or_pivotal?
    [VENDOR_ALPINE, VENDOR_PIVOTAL].include? self[:vendor]
  end

  def license_path
    Rails.root.join 'config', 'chorus.license'
  end

  def default_license_path
    Rails.root.join 'config', 'chorus.license.default'
  end
end
