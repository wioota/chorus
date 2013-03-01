class Dataset < ActiveRecord::Base
  include Stale
  include SoftDelete
  include TaggableBehavior
  include Notable

  belongs_to :schema, :counter_cache => :active_tables_and_views_count

  after_update :update_active_tables_and_views_counter_cache_on_schema

  validates_presence_of :schema
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:schema_id,  :type, :deleted_at]

  has_many :activities, :as => :entity
  has_many :events, :through => :activities
  has_many :comments, :through => :events
  has_many :associated_datasets, :dependent => :destroy
  has_many :bound_workspaces, :through => :associated_datasets, :source => :workspace
  has_many :import_schedules, :foreign_key => 'source_dataset_id', :dependent => :destroy
  has_many :imports, :foreign_key => 'source_dataset_id'

  searchable_model :if => :should_reindex? do
    text :name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
    text :database_name, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :table_description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :schema_name, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :column_name, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :column_description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :query, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
  end

  has_shared_search_fields [
                               {:type => :integer, :name => :instance_account_ids, :options => {:multiple => true}},
                               {:type => :integer, :name => :found_in_workspace_id, :options => {:multiple => true}}
                           ]
  attr_accessor :highlighted_attributes, :search_result_notes, :skip_search_index
  attr_accessible :name

  delegate :data_source, :accessible_to, :connect_with, :connect_as, :to => :schema

  def self.add_search_permissions(current_user, search)
    search.build do
      any_of do
        without :security_type_name, Dataset.security_type_name
        account_ids = current_user.accessible_account_ids
        with :instance_account_ids, account_ids unless account_ids.blank?
      end

      any_of do
        without :security_type_name, "ChorusView"
        with :member_ids, current_user.id
        with :public, true
      end
    end
  end

  def self.with_name_like(name)
    if name.present?
      where("name ILIKE ?", "%#{name}%")
    else
      scoped
    end
  end

  def self.list_order
    order("lower(replace(datasets.name,'_',''))")
  end

  def self.tables
    where("datasets.type LIKE '%Table'")
  end

  def self.views
    views_tables.where("datasets.type LIKE '%View'")
  end

  def self.views_tables
    where("datasets.type <> 'ChorusView'")
  end

  def self.chorus_views
    where(:type => 'ChorusView')
  end

  def self.filter_by_name(datasets, name)
    if name.present?
      datasets.select do |dataset|
        dataset.name =~ /#{name}/i
      end
    else
      datasets
    end
  end

  def should_reindex?
    !stale? && !skip_search_index
  end

  def self.find_and_verify_in_source(dataset_id, user)
    dataset = find(dataset_id)
    unless dataset.verify_in_source(user)
      raise ActiveRecord::RecordNotFound
    end
    dataset
  end

  def self.refresh(account, schema, options = {})
    schema.refresh_datasets account, options
  end

  def query_setup_sql
    ""
  end

  def all_rows_sql(limit = nil)
    Arel::Table.new(name).project('*').take(limit).to_sql
  end

  def preview_sql
    all_rows_sql
  end

  def as_sequel
    Sequel.qualify(schema.name, name)
  end

  def entity_type_name
    'dataset'
  end

  def type_name
    'Dataset'
  end

  def schema_name
    schema.name
  end

  def column_name
    column_data.map(&:name)
  end

  def column_description
    column_data.map(&:description).compact
  end

  def column_data
    @column_data ||= DatasetColumn.columns_for(schema.data_source.owner_account, self)
  end

  def table_description
    DatasetStatistics.build_for(self, schema.data_source.owner_account).description
  rescue
    nil
  end

  private

  def update_active_tables_and_views_counter_cache_on_schema
    if changed_attributes.include?('stale_at')
      if stale?
        Schema.decrement_counter(:active_tables_and_views_count, schema_id)
      else
        Schema.increment_counter(:active_tables_and_views_count, schema_id)
      end
    end
  end
end