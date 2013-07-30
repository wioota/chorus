class ImportSourceDataTask < JobTask

  has_additional_data :source_id, :destination_id, :destination_name, :truncate, :row_limit

  before_save :build_task_name

  def self.assemble!(params, job)
    task = ImportSourceDataTask.new(params)
    task.job = job
    task.save!
    task
  end

  private

  def build_task_name
    if source_id
      source_name = Dataset.find(source_id).name
      self.name = 'Import ' + source_name
    end
  end
end