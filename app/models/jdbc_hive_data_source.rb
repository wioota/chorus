class JdbcHiveDataSource < JdbcDataSource

  attr_accessible :hive, :hive_kerberos, :hive_hadoop_version, :hive_kerberos_principal, :hive_kerberos_keytab_location

  def attempt_connection(user)
    # pass empty block to attempt connection and ensure connection disconnects
    # so we do not leak connections
    connect_as(user).with_connection {}
  end

  def valid_db_credentials?(account)
    success = true
    connect_with(account).connect!
  rescue DataSourceConnection::InvalidCredentials
    success = false
  ensure
    connect_with(account).disconnect
    success
  end

  private

end
