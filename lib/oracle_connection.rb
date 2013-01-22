require_relative 'data_source_connection'
if ChorusConfig.instance.oracle_configured?
  begin
    require_relative 'libraries/ojdbc6.jar'
  rescue LoadError
    pa "Error loading Oracle driver"
  end
elsif ChorusConfig.instance.oracle_driver_expected_but_missing?
  pa "Oracle driver ojdbc6.jar not found"
end


class OracleConnection < DataSourceConnection
  class DatabaseError < Error
    def error_type
      error_code = @exception.wrapped_exception && @exception.wrapped_exception.respond_to?(:get_error_code) && @exception.wrapped_exception.get_error_code
      pa "Oracle error code = #{error_code}"
      errortype = case error_code
        when 1017 then :INVALID_PASSWORD
        when 12514 then :DATABASE_MISSING
        when 17002 then :INSTANCE_UNREACHABLE
        else :GENERIC
      end
      pa "Oracle error code type = #{errortype}"
      errortype
    end

    private

    def sanitize_message(message)
      # jdbc:oracle:thin:username/password@//host:port/database
      message.gsub /\:[^\:]+\/.+@\/\//, ':xxxx/xxxx@//'
    end
  end

  def initialize(details)
    @settings = details
  end

  def connect!
    @connection ||= Sequel.connect(db_url, :test => true)
  rescue Sequel::DatabaseError => e
    raise OracleConnection::DatabaseError.new(e)
  end

  def connected?
    !!@connection
  end

  def disconnect
    @connection.disconnect
    @connection = nil
  end

  private

  def db_url
    "jdbc:oracle:thin:#{@settings[:username]}/#{@settings[:password]}@//#{@settings[:host]}:#{@settings[:port]}/#{@settings[:database]}"
  end
end