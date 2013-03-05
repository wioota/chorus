class OracleSchema < Schema
  include Stale

  attr_accessible :data_source
  alias_attribute :parent, :data_source

  has_many :instance_account_permissions, :as => :accessed
  has_many :instance_accounts, :through => :instance_account_permissions

  belongs_to :data_source, {
      :polymorphic => true,
      :foreign_key => 'parent_id',
      :foreign_type => 'parent_type',
      :class_name => 'OracleDataSource'
  }

  validates :data_source, :presence => true

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

  def self.reindex_datasets(schema_id)
    find(schema_id).datasets.not_stale.each do |dataset|
      begin
        dataset.solr_index
      rescue => e
        Chorus.log_error "Error in OracleSchema.reindex_datasets: #{e.message}"
      end
    end
    Sunspot.commit
  end
end