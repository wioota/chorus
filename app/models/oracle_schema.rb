class OracleSchema < Schema
  include Stale

  attr_accessible :data_source
  alias_attribute :parent, :data_source

  belongs_to :data_source, {
      :polymorphic => true,
      :foreign_key => 'parent_id',
      :foreign_type => 'parent_type',
      :class_name => 'OracleDataSource'
  }

  validates :data_source, :presence => true
  validates :name, :presence => true, :uniqueness => { :scope => [:parent_id, :parent_type] }
  has_many :active_tables_and_views, :foreign_key => :schema_id, :class_name => 'Dataset',
           :conditions => ['stale_at IS NULL']

  def connect_with(account)
    ::OracleConnection.new(
        :username => account.db_username,
        :password => account.db_password,
        :host => data_source.host,
        :port => data_source.port,
        :database => data_source.db_name,
        :schema => name
    )
  end

  def class_for_type(type)
    type == 't' ? OracleTable : OracleView
  end
end