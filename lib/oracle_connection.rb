require_relative 'data_source_connection'
begin
  require_relative 'ojdbc6.jar'
rescue LoadError
  pa "Oracle driver not found"
end


class OracleConnection < DataSourceConnection
  def initialize(details)
    @settings = details
  end

  def connect!
    @connection ||= Sequel.connect(db_url, :test => true)
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