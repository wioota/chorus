class JdbcHiveDataSource < JdbcDataSource

  attr_accessible :hive, :hive_kerberos, :hive_hadoop_version, :hive_kerberos_principal, :hive_kerberos_keytab_location

  def self.type_name
    'JdbcHiveDataSource'
  end

  def attempt_connection(user)
    # pass empty block to attempt connection and ensure connection disconnects
    # so we do not leak connections
    #connect_as(user).with_connection {}
  end

  private

end
