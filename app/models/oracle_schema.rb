class OracleSchema < Schema
  include Stale

  attr_accessible :data_source
  alias_attribute :data_source, :parent

  has_many :instance_account_permissions, :as => :accessed
  has_many :instance_accounts, :through => :instance_account_permissions

  validates :data_source, :presence => true

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