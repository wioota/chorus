require 'sequel'

module GreenplumConnection
  class InstanceUnreachable < StandardError;
  end

  @@gpdb_login_timeout = 10

  def self.gpdb_login_timeout
    @@gpdb_login_timeout
  end

  class Base

    def initialize(details)
      @settings = details
    end

    def connect!
      @connection = Sequel.connect(db_url)

      begin
        @connection.test_connection
      rescue Sequel::DatabaseConnectionError => e
        raise InstanceUnreachable
      end
    end

    def disconnect
      @connection.disconnect if @connection
      @connection = nil
    end

    METHODS = [:username, :password, :host, :port, :database]
    METHODS.each do |meth|
      define_method(meth) { @settings[meth.to_sym] }
    end

    def connected?
      !!@connection
    end

    private

    def with_connection
      connect!
      yield
    ensure
      disconnect
    end

    def db_url
      query_params = URI.encode_www_form(:user => @settings[:username], :password => @settings[:password], :loginTimeout => GreenplumConnection.gpdb_login_timeout)
      "jdbc:postgresql://#{@settings[:host]}:#{@settings[:port]}/#{@settings[:database]}?" << query_params
    end
  end

  class DatabaseConnection < Base
    def schemas
      with_connection { @connection.fetch(SCHEMAS_SQL).map { |row| row[:schema_name] } }
    end

    def create_schema(name)
      with_connection { @connection.create_schema(name) }
    end

    private

    SCHEMAS_SQL = <<-SQL
      SELECT
        schemas.nspname as schema_name
      FROM
        pg_namespace schemas
      WHERE
        schemas.nspname NOT LIKE 'pg_%'
        AND schemas.nspname NOT IN ('information_schema', 'gp_toolkit', 'gpperfmon')
      ORDER BY lower(schemas.nspname)
    SQL
  end

  class InstanceConnection < Base
    def databases
      with_connection { @connection.fetch(DATABASES_SQL).map { |row| row[:database_name] } }
    end

    private

    DATABASES_SQL = <<-SQL
      SELECT
        datname as database_name
      FROM
        pg_database
      WHERE
        datallowconn IS TRUE AND datname NOT IN ('postgres', 'template1')
        ORDER BY lower(datname) ASC
    SQL
  end
end