require 'clockwork'
require 'queue_classic'

module QC
  def self.log(data)
    Scrolls.log({ :timestamp => Time.current.to_s, :lib => :queue_classic, :level => :debug}.merge(data))
  end
end

module Clockwork
  configure do |config|
    logger = Logger.new(STDOUT)
    logger.formatter = Logger::Formatter.new
    logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    config[:logger] = logger
  end
end