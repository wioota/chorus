require 'sequel'

class DataSourceConnection
  class Error < StandardError
    def initialize(exception = nil)
      if exception
        super(exception.message)
        @exception = exception
      end
    end

    def to_s
      sanitize_message super
    end

    def message
      sanitize_message super
    end

    private

    def sanitize_message(message)
      message
    end
  end
end