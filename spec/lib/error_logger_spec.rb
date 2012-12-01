require 'error_logger'
require 'timecop'
require 'spec/support/rr'

unless defined? Rails
  class Rails
    unless defined?(self.logger)
      def self.logger
      end
    end
  end
end

describe Chorus do
  describe "#log_error" do
    it "prepends the date and time" do
      Timecop.travel(Time.local(2012, 11, 11, 11, 0, 0)) do
        mock(Rails.logger).error("2012-11-11 11:00:00 ERROR: Help")
        Chorus.log_error("Help")
      end
    end
  end
end
