class JdbcDataSource < DataSource

  alias_attribute :url, :host

  def self.create_for_user(user, data_source_hash)
    user.jdbc_data_sources.create!(data_source_hash, :as => :create)
  end

  def valid_db_credentials?(account)
    true
  end

end