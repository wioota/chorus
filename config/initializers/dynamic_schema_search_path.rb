module ::ArJdbc
  module PostgreSQL
# Sets the schema search path to a string of comma-separated schema names.
# Names beginning with $ have to be quoted (e.g. $user => '$user').
# See: http://www.postgresql.org/docs/current/static/ddl-schemas.html
#
# This should be not be called manually but set in database.yml.
    def schema_search_path=(schema_csv)
      if schema_csv
        execute "SET search_path TO #{schema_csv}"
        @schema_search_path = schema_csv
      end
    end

# Returns the active schema search path.
    def schema_search_path
      @schema_search_path ||= exec_query('SHOW search_path', 'SCHEMA')[0]['search_path']
    end

# Returns the current schema name.
    def current_schema
      exec_query('SELECT current_schema', 'SCHEMA')[0]["current_schema"]
    end
  end
end

# patches postgresql_connection to set standard_conforming_strings to off.
class ActiveRecord::Base
  class << self
    def postgresql_connection(config)
      require "arjdbc/postgresql"
      config[:host] ||= "localhost"
      config[:port] ||= 5432
      config[:url] ||= "jdbc:postgresql://#{config[:host]}:#{config[:port]}/#{config[:database]}"
      config[:url] << config[:pg_params] if config[:pg_params]
      config[:driver] ||= "org.postgresql.Driver"
      config[:adapter_class] = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      config[:adapter_spec] = ::ArJdbc::PostgreSQL
      conn = jdbc_connection(config)
      conn.execute("SET SEARCH_PATH TO #{config[:schema_search_path]}") if config[:schema_search_path]
      conn.execute('SET standard_conforming_strings = off', 'SCHEMA')
      conn
    end
    alias_method :jdbcpostgresql_connection, :postgresql_connection
  end
end
