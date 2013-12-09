class JdbcDataSource < DataSource

  alias_attribute :url, :host

  has_many :schemas, :as => :parent, :class_name => 'JdbcSchema'

  def self.create_for_user(user, data_source_hash)
    user.jdbc_data_sources.create!(data_source_hash, :as => :create)
  end

  def refresh_databases(options={})
    refresh_schemas options
  end

  def refresh_schemas(options={})
    schema_permissions = update_schemas(options)
    update_permissions(schema_permissions)
    schemas.map(&:name)
  end

  def update_schemas(options)

  end

  def update_permissions(schema_permissions)

  end

  def valid_db_credentials?(account)
    true
  end

  private

  def connection_class
    JdbcConnection
  end
end