class OracleInstance < DataSource
  validates :host, :presence => true
  validates :port, :presence => true
  validates_associated :owner_account, :if => :validate_owner?
  attr_accessor :db_username, :db_password

  before_validation :build_instance_account_for_owner, :on => :create

  def connect_with(account)
    OracleConnection.new(
        :username => account.db_username,
        :password => account.db_password,
        :host => host,
        :port => port,
        :database => maintenance_db
    )
  end

  private

  def validate_owner?
    self.changed.include?('host') || self.changed.include?('port') || self.changed.include?('maintenance_db')
  end

  def build_instance_account_for_owner
    build_owner_account(:owner => owner, :db_username => db_username, :db_password => db_password)
  end
end