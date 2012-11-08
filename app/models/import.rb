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

  validate :table_does_not_exist, :if => :new_table, :on => :create
  validate :table_does_exist, :unless => :new_table, :on => :create

  validates :source_dataset, :presence => true, :unless => :file_name
  validates :file_name, :presence => true, :unless => :source_dataset
  validate :tables_have_consistent_schema, :unless => :new_table, :on => :create

  # Running an import must use this method to ensure the call is serializable
  # and can be moved into a job
  def self.run(import_id)
    Import.find(import_id).run
  end

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

  def run
    import_attributes = attributes.symbolize_keys
    import_attributes.slice!(:workspace_id, :to_table, :new_table, :sample_count, :truncate)

    import_attributes[:import_id] = id
    if workspace.sandbox.database != source_dataset.schema.database
      Gppipe.run_import(source_dataset.id, user.id, import_attributes)
    else
      GpTableCopier.run_import(source_dataset.id, user.id, import_attributes)
    end
    import_schedule.update_attribute(:destination_dataset_id, destination_dataset_id) if new_table? && import_schedule
    import_schedule.update_attribute(:new_table, false) if new_table? && import_schedule
  end
end