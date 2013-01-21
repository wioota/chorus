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