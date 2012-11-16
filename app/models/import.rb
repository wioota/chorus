# An immutable record of an Import action
# Can be a user-initiated import or from an ImportSchedule
# Belongs to a dataset, so it must have a sandbox (???)

# Todo: perhaps get rid of workspace_id for schema_id instead.
class Import < ActiveRecord::Base
  include ImportMixins

  attr_accessible :to_table, :new_table, :sample_count, :truncate
  attr_accessible :file_name # only for CSV files

  belongs_to :source_dataset, :class_name => 'Dataset'
  belongs_to :user
  belongs_to :import_schedule

  validates :to_table, :presence => true

  validates :user, :presence => true

  validate :workspace_is_not_archived

  validate :table_does_not_exist, :if => :new_table, :on => :create
  validate :table_does_exist, :unless => :new_table, :on => :create

  validates :source_dataset, :presence => true, :unless => :file_name
  validates :file_name, :presence => true, :unless => :source_dataset
  validate :tables_have_consistent_schema, :unless => :new_table, :unless => :file_name, :on => :create

  def create_import_event
    dst_table = workspace.sandbox.datasets.find_by_name(to_table) unless new_table
    Events::DatasetImportCreated.by(user).add(
        :workspace => workspace,
        :source_dataset => source_dataset,
        :dataset => dst_table,
        :destination_table => to_table,
        :reference_id => id,
        :reference_type => 'Import'
    )
  end
end