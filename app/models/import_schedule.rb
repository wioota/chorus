class ImportSchedule < ActiveRecord::Base
  include SoftDelete
  include ImportMixins

  belongs_to :source_dataset, :class_name => 'Dataset'
  belongs_to :user
  has_many :imports

  attr_accessible :to_table, :new_table, :sample_count,
                  :truncate, :start_datetime, :end_date, :frequency

  before_save :set_next_import

  scope :ready_to_run, lambda { where('next_import_at <= ?', Time.current.utc) }

  validates :to_table, :presence => true
  validates :source_dataset, :presence => true
  validates :user, :presence => true
  validates :start_datetime, :presence => true
  validates :end_date, :presence => true
  validate :workspace_is_not_archived, :unless => :deleted?

  validates :frequency, :inclusion => {:in => %w( daily weekly monthly )}

  validate :table_does_not_exist, :if => :new_table
  validate :table_does_exist, :if => Proc.new { |schedule| schedule.new_table == false }
  validate :tables_have_consistent_schema, :if => Proc.new { |schedule| schedule.new_table == false }

  #TODO, get rid of unneeded columns, dataset_import_created_event_id, last_scheduled_at

  def create_import_event
    dst_table = workspace.sandbox.datasets.find_by_name(to_table) unless new_table
    Events::DatasetImportCreated.by(user).add(
        :workspace => workspace,
        :source_dataset => source_dataset,
        :dataset => dst_table,
        :destination_table => to_table,
        :reference_id => id,
        :reference_type => 'ImportSchedule'
    )
  end

  def set_next_import
    val = ImportTime.new(
        start_datetime,
        end_date,
        frequency,
        Time.current
    ).next_import_time
    self.next_import_at = val
  end

  def create_duplicate_import_schedule (source_dataset_id)
    new_import_schedule = ImportSchedule.new
    new_import_schedule.frequency = frequency
    new_import_schedule.destination_dataset_id = destination_dataset_id
    new_import_schedule.to_table = to_table
    new_import_schedule.source_dataset_id = source_dataset_id
    new_import_schedule.truncate = truncate
    new_import_schedule.sample_count = sample_count
    new_import_schedule.new_table = new_table
    new_import_schedule.user_id = user_id
    new_import_schedule.start_datetime = start_datetime
    new_import_schedule.end_date = end_date
    new_import_schedule.workspace_id = workspace_id
    new_import_schedule
  end
end