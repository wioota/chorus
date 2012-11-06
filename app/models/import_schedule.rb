class ImportSchedule < ActiveRecord::Base
  include SoftDelete
  include ImportMixins

  belongs_to :source_dataset, :class_name => 'Dataset'
  belongs_to :user
  has_many :imports

  attr_accessible :to_table, :new_table, :sample_count,
                  :truncate, :start_datetime, :end_date, :frequency

  before_save :set_next_import

  scope :ready_to_run, lambda { where('next_import_at <= ?', Time.current) }

  validates :to_table, :presence => true
  validates :source_dataset, :presence => true
  validates :user, :presence => true
  validates :start_datetime, :presence => true
  validates :end_date, :presence => true

  validates :frequency, :inclusion => {:in => %w( daily weekly monthly )}

  validate :table_does_not_exist, :if => :new_table
  validate :table_does_exist, :unless => :new_table
  validate :tables_have_consistent_schema, :unless => :new_table

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
end