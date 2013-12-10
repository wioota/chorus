class JdbcConnection < DataSourceConnection
  class DatabaseError < Error; end

  def db_url
    @data_source.url
  end

  def db_options
    super.merge({
      :user => @account.db_username,
      :password => @account.db_password
    })
  end

  def connected?
    !!@connection
  end

  def disconnect
    @connection.disconnect if @connection
    @connection = nil
  end

  def schemas
    with_connection { |connection| connection.schemas }
  end

  #def tables
  #  with_connection { |connection| connection.tables}
  #end

  def with_connection(options = {})
    connect!
    yield @connection
  rescue Sequel::DatabaseError => e
    raise JdbcConnection::DatabaseError.new(e)
  ensure
    disconnect
  end

  def self.error_class
    JdbcConnection::DatabaseError
  end
end