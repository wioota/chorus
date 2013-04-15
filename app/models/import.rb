class Import < ActiveRecord::Base
  include ImportMixins
  include UnscopedBelongsTo

  attr_accessible :to_table, :new_table, :sample_count, :truncate, :user
  attr_accessible :file_name # only for CSV files

  unscoped_belongs_to :source_dataset, :class_name => 'Dataset'
  belongs_to :user
  belongs_to :import_schedule

  validates :to_table, :presence => true
  validates :user, :presence => true

  validate :table_does_not_exist, :if => :new_table, :on => :create
  validates :scoped_source_dataset, :presence => true, :unless => :file_name
  validates :file_name, :presence => true, :unless => :scoped_source_dataset
  validate :tables_have_consistent_schema, :unless => :new_table, :unless => :file_name, :on => :create

  after_create :create_import_event
  after_create :enqueue_import, :unless => :file_name

  def create_import_event
    raise "implement me!"
  end

  def copier_class
    raise "implement me!"
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

  def handle
    "#{created_at.to_i}_#{id}"
  end

  def update_status(status, message = nil)
    return unless success.nil?

    passed = (status == :passed)

    touch(:finished_at)
    update_attribute(:success, passed)

    if passed
      refresh_schema
      mark_as_success
    else
      create_failed_event_and_notification(message)
    end
  end

  def cancel(success, message = nil)
    log "Terminating import: #{inspect}"
    update_status(success ? :passed : :failed, message)
  end

  def enqueue_import
    QC.enqueue_if_not_queued("ImportExecutor.run", id)
  end

  def source
    source_dataset
  end

  def validate_source!
    raise "Original source dataset #{source.scoped_name} has been deleted" if source.deleted?
  end

  private

  def named_pipe
    return @named_pipe if @named_pipe
    return unless ChorusConfig.instance.gpfdist_configured?
    dir = Pathname.new ChorusConfig.instance['gpfdist.data_dir']
    @named_pipe = Dir.glob(dir.join "pipe*_#{handle}").first
  end

  def log(message)
    Rails.logger.info("Import Termination: #{message}")
  end

  def update_import_created_event
    event = created_event_class.find_for_import(self)

    if event
      event.dataset = find_destination_dataset
      event.save!
    end
  end

  def refresh_schema
    # update rails db for new dataset
    destination_account = schema.database.data_source.account_for_user!(user)
    schema.refresh_datasets(destination_account) rescue ActiveRecord::JDBCError
  end
end