module Chorus
  def self.log_error(message)
    prefix = Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")
    Rails.logger.error("#{prefix} ERROR: #{message}")
  end
end
