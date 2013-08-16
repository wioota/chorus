class ImportSourceDataTask < JobTask
  validate :destination_name_is_unique

  belongs_to :payload, :class_name => 'ImportTemplate', :autosave => true
  delegate :workspace, :to => :job

  def attach_payload(params)
    self.build_payload(params)
  end

  def perform
    result = JobTaskResult.create(:started_at => Time.current, :name => build_task_name)
    import = payload.create_import
    ImportExecutor.run import.id
    payload.set_destination_id! if payload.new_table_import?
    result.finish :status => JobTaskResult::SUCCESS
  rescue StandardError => e
    result.finish :status => JobTaskResult::FAILURE, :message => e.message
  end

  def update_attributes(params)
    payload.update_attributes(params)
    super
  end

  def build_task_name
    self.name = "Import from #{payload.source.name}"
  end

  private

  def destination_name_is_unique
    if payload.new_table_import? && destination_already_exists?
      errors.add(:base, :table_exists, {:table_name => payload.destination_name})
    end
  end

  def destination_already_exists?
    workspace.sandbox.datasets.find_by_name(payload.destination_name)
  end
end