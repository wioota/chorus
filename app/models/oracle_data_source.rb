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
    schemas = Schema.refresh(owner_account, self, options.reverse_merge(:refresh_all => true))
    update_permissions
    schemas
  end

  def update_permissions
    schema_permissions = {}
    accounts.each do |account|
      begin
        connect_with(account).schemas.each do |schema|
          schema_permissions[schema] ||= []
          schema_permissions[schema] << account.id
        end
      rescue => e
        pa e.message
      end
    end

    schema_permissions.each do |schema_name, account_ids|
      schema = schemas.find_by_name(schema_name)
      schema.instance_account_ids = account_ids
      schema.save!
    end
  end

  private

  def validate_owner?
    self.changed.include?('host') || self.changed.include?('port') || self.changed.include?('db_name')
  end

  def build_instance_account_for_owner
    build_owner_account(:owner => owner, :db_username => db_username, :db_password => db_password)
  end
end