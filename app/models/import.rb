# An immutable record of an Import action
# Can be a user-initiated import or from an ImportSchedule

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
  validates :source_dataset, :presence => true, :unless => :file_name
  validates :file_name, :presence => true, :unless => :source_dataset
  validate :tables_have_consistent_schema, :unless => :new_table, :unless => :file_name, :on => :create

  after_create :create_import_event
  after_create { QC.enqueue_if_not_queued("ImportExecutor.run", id) unless file_name }

  def generate_key
    update_attribute(:stream_key, SecureRandom.hex(20))
  end

  def mark_as_success
    set_destination_dataset_id
    save(:validate => false)
    create_passed_event_and_notification
    update_import_created_event
    import_schedule.update_attributes({:new_table => false}) if import_schedule
  end

  def workspace_import?
    self.is_a?(WorkspaceImport)
  end

  private

  def update_import_created_event
    event = created_event_class.find_for_import(self)

    if event
      event.dataset = find_destination_dataset
      event.save!
    end
  end
end