class OracleDataSource < DataSource
  validates :host, :presence => true
  validates :port, :presence => true
  validates_associated :owner_account, :if => :validate_owner?
  attr_accessor :db_username, :db_password

  before_validation :build_instance_account_for_owner, :on => :create

  has_many :schemas, :as => :parent, :class_name => 'OracleSchema'

  def self.create_for_user(user, params)
    unless ChorusConfig.instance.oracle_configured?
      raise ApiValidationError.new(:oracle, :not_configured)
    end

    user.oracle_data_sources.create!(params) do |data_source|
      data_source.shared = params[:shared]
    end
  end

  def self.type_name
    'Instance'
  end

  def connect_with(account)
    OracleConnection.new(
        :username => account.db_username,
        :password => account.db_password,
        :host => host,
        :port => port,
        :database => db_name,
        :logger => Rails.logger
    )
  end

  def refresh_databases(options={})
    refresh_schemas options
  end

  # Used by search
  def refresh_schemas(options={})
    schema_permissions = update_schemas(options)
    update_permissions(schema_permissions)
    schemas.map(&:name)
  end

  private

  def update_permissions(schema_permissions)
    schema_permissions.each do |schema_id, account_ids|
      schema = schemas.find(schema_id)
      schema.instance_account_ids = account_ids
      schema.save!
      QC.enqueue_if_not_queued("OracleSchema.reindex_datasets", schema.id)
    end
  end

  def update_schemas(options)
    begin
      schema_permissions = {}
      accounts.each do |account|
        schemas = Schema.refresh(account, self, options.reverse_merge(:refresh_all => true))
        schemas.each do |schema|
          schema_permissions[schema.id] ||= []
          schema_permissions[schema.id] << account.id
        end
      end
    rescue => e
      Chorus.log_error "Error refreshing Oracle Schema #{e.message}"
    end
    schema_permissions
  end

  def validate_owner?
    self.changed.include?('host') || self.changed.include?('port') || self.changed.include?('db_name')
  end

  def build_instance_account_for_owner
    build_owner_account(:owner => owner, :db_username => db_username, :db_password => db_password)
  end
end