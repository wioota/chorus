require 'error_logger'

module Gpdb
  class InstanceStillProvisioning < StandardError; end
  class InstanceOverloaded < StandardError; end
  class InstanceUnavailable < StandardError; end

  module ConnectionBuilder
    def self.connect!(gpdb_instance, account, database_name=nil)
      raise InstanceStillProvisioning if gpdb_instance.state == "provisioning"

      connection = ActiveRecord::Base.postgresql_connection(
        :host => gpdb_instance.host,
        :port => gpdb_instance.port,
        :database => database_name || gpdb_instance.maintenance_db,
        :username => account.db_username,
        :password => account.db_password,
        :adapter => "jdbcpostgresql"
      )
      # TODO: this yield should really be after most of the exception handling [#39664445]
      yield connection if block_given?
    rescue ActiveRecord::JDBCError => e
      friendly_message = "Failed to establish JDBC connection to #{gpdb_instance.host}:#{gpdb_instance.port}"
      Chorus.log_error(friendly_message + " - " + e.message)

      if e.message.include?("password")
        raise ActiveRecord::JDBCError.new("Password authentication failed for user '#{account.db_username}'")
      elsif e.message.include?("too many clients")
        raise InstanceOverloaded
      else
        raise InstanceUnavailable
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
  end
end
