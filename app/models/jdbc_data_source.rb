class JdbcDataSource < DataSource
  include SingleLevelDataSourceBehavior

  alias_attribute :url, :host

  has_many :schemas, :as => :parent, :class_name => 'JdbcSchema'

  def self.create_for_user(user, data_source_hash)
    user.jdbc_data_sources.create!(data_source_hash, :as => :create)
  end

  def valid_db_credentials?(account)
    true
  end

  private

  def connection_class
    JdbcConnection
  end
end