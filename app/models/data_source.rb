class DataSource < ActiveRecord::Base
  include SoftDelete

  attr_accessible :name, :description, :host, :port, :db_name, :db_username, :db_password, :as => [:default, :create]
  attr_accessible :shared, :as => :create

  belongs_to :owner, :class_name => 'User'
  has_many :accounts, :class_name => 'InstanceAccount', :inverse_of => :instance, :foreign_key => "instance_id", :dependent => :destroy
  has_one :owner_account, :class_name => 'InstanceAccount', :foreign_key => "instance_id", :inverse_of => :instance, :conditions => proc { {:owner_id => owner_id} }

  has_many :activities, :as => :entity
  has_many :events, :through => :activities

  validates_presence_of :name, :db_name
  validates_numericality_of :port, :only_integer => true, :if => :host?
  validates_length_of :name, :maximum => 64

  after_create :create_instance_created_event, :if => :current_user
  validates_with DataSourceNameValidator

  def self.by_type(entity_type)
    if entity_type == "gpdb_data_source"
      where(type: "GpdbDataSource")
    elsif entity_type == "oracle_data_source"
      where(type: "OracleDataSource")
    else
      self
    end
  end

  def self.unshared
    where("data_sources.shared = false OR data_sources.shared IS NULL")
  end

  def self.accessible_to(user)
    where('data_sources.shared OR data_sources.owner_id = :owned OR data_sources.id IN (:with_membership)',
          owned: user.id,
          with_membership: user.instance_accounts.pluck(:instance_id)
    )
  end

  def accessible_to(user)
    DataSource.accessible_to(user).include?(self)
  end

  def self.refresh_databases instance_id
    find(instance_id).refresh_databases
  end

  def self.create_for_entity_type(entity_type, user, data_source_hash)
    entity_class = entity_type.classify.constantize rescue NameError
    raise ApiValidationError.new(:entity_type, :invalid) unless entity_class < DataSource
    entity_class.create_for_user(user, data_source_hash)
  end

  def valid_db_credentials?(account)
    success = true
    connection = connect_with(account).connect!
  rescue DataSourceConnection::Error => e
    raise unless e.error_type == :INVALID_PASSWORD
    success = false
  ensure
    connection.try(:disconnect)
    success
  end

  def connect_as_owner
    connect_with(owner_account)
  end

  def connect_as(user)
    connect_with(account_for_user!(user))
  end

  def account_for_user(user)
    if shared?
      owner_account
    else
      account_owned_by(user)
    end
  end

  def account_for_user!(user)
    account_for_user(user) || (raise ActiveRecord::RecordNotFound.new)
  end

  def data_source
    self
  end

  def self.refresh(id, options={})
    symbolized_options = options.symbolize_keys
    symbolized_options[:new] = symbolized_options[:new].to_s == "true" if symbolized_options[:new]
    find(id).refresh symbolized_options
  end

  def refresh(options={})
    options[:skip_dataset_solr_index] = true if options[:new]
    refresh_databases options
    refresh_schemas options

    if options[:skip_dataset_solr_index]
      #The first refresh_all did not index the datasets in solr due to performance.
      refresh_schemas options.merge(:force_index => true)
    end
  end

  private

  def account_owned_by(user)
    accounts.find_by_owner_id(user.id)
  end

  def create_instance_created_event
    Events::DataSourceCreated.by(current_user).add(:data_source => self)
  end

end