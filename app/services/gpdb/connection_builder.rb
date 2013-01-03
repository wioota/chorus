require 'error_logger'

module Gpdb
  class InstanceOverloaded < StandardError; end
  class InstanceUnreachable < StandardError; end

  mattr_accessor :gpdb_login_timeout
  self.gpdb_login_timeout = 10

  module ConnectionBuilder
    def self.connect!(gpdb_instance, account, database_name=nil)
      connection = ActiveRecord::Base.postgresql_connection( connection_params(gpdb_instance, account, database_name) )

      # TODO: this yield should really be after most of the exception handling [#39664445]
      yield connection if block_given?
    rescue ActiveRecord::JDBCError => e
      friendly_message = "Failed to establish JDBC connection to #{gpdb_instance.host}:#{gpdb_instance.port}"
      Chorus.log_error(friendly_message + " - " + e.message)

      if e.message.include?("password")
        raise ActiveRecord::JDBCError.new("Password authentication failed for user '#{account.db_username}'")
      elsif e.message.include?("too many clients")
        raise InstanceOverloaded
      elsif e.message.include?("Connection attempt timed out") || e.message.include?("The connection attempt failed")
        raise InstanceUnreachable
      else
        raise
      end
    rescue ActiveRecord::StatementInvalid => e
      friendly_message = "#{Time.current.strftime("%Y-%m-%d %H:%M:%S")} ERROR: SQL Statement Invalid"
      Rails.logger.warn(friendly_message + " - " + e.message)
      raise e
    ensure
      connection.try(:disconnect!)
    end

    def self.url(database, account)
      "jdbc:postgresql://#{database.gpdb_instance.host}:#{database.gpdb_instance.port}/#{database.name}?user=#{account.db_username}&password=#{account.db_password}"
    end

    def self.connection_params(gpdb_instance, account, database_name)
      connection_params = {
        :host => gpdb_instance.host,
        :port => gpdb_instance.port,
        :database => database_name || gpdb_instance.maintenance_db,
        :username => account.db_username,
        :password => account.db_password,
        :adapter => "jdbcpostgresql"
      }
      connection_params[:pg_params] = "?loginTimeout=#{Gpdb.gpdb_login_timeout}" if Gpdb.gpdb_login_timeout
      connection_params
    end
  end
end
