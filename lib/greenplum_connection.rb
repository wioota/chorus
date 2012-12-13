require 'sequel'

module GreenplumConnection
  class InstanceUnreachable < StandardError; end

  class InstanceConnection
    attr_reader :settings

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

    def schemas
      connect!
      @connection.fetch(SCHEMAS_SQL).map { |row| row[:schema_name] }
    ensure
      disconnect
    end

    def connected?
      !!@connection
    end

    private

    def db_url
      query_params = URI.encode_www_form(:user => @settings[:username], :password => @settings[:password], :loginTimeout => 3)
      "jdbc:postgresql://#{@settings[:host]}:#{@settings[:port]}/#{@settings[:database]}?" << query_params
    end

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
end