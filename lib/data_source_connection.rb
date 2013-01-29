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

  def fetch(sql, parameters = {})
    with_connection { @connection.fetch(sql, parameters).all }
  end

  def fetch_value(sql)
    result = with_connection { @connection.fetch(sql).limit(1).first }
    result && result.first[1]
  end

  def execute(sql)
    with_connection { @connection.execute(sql) }
    true
  end
end