class ImportSourceDataTask < JobTask

  has_additional_data :source_id, :destination_id, :destination_name, :truncate, :row_limit

  before_save :build_task_name

  validate :destination_name_is_unique

  def self.assemble!(params, job)
    task = ImportSourceDataTask.new(params)
    task.job = job
    task.save!
    task
  end

  def execute
    true
  end

  private

  def build_task_name
    if source_id
      source_name = Dataset.find(source_id).name
      self.name = 'Import ' + source_name
    end
  end

  def destination_name_is_unique
    if job.workspace.sandbox.datasets.find_by_name(destination_name)
      errors.add(:base, :table_exists, {:table_name => destination_name})
    end
  end
end