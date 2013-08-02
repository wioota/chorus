class ImportSourceDataTask < JobTask

  has_additional_data :source_id, :destination_id, :destination_name, [:truncate, :boolean], :row_limit

  before_save :build_task_name

  validate :destination_name_is_unique

  def self.assemble!(params, job)
    task = ImportSourceDataTask.new(params)
    task.job = job
    task.save!
    task
  end

  def execute
    import = create_import
    run_import(import.id)
    set_destination_id! if new_table_import?
    true
  rescue StandardError => e
    raise JobTaskFailure.new(e)
  end

  def source_dataset
    Dataset.find(source_id) if source_id
  end

  def destination_dataset_name
    destination_name || Dataset.find(destination_id).name
  end

  private

  def build_task_name
    if source_dataset
      source_name = source_dataset.name
      self.name = 'Import ' + source_name
    end
  end

  def destination_name_is_unique
    if new_table_import? && workspace.sandbox.datasets.find_by_name(destination_name)
      errors.add(:base, :table_exists, {:table_name => destination_name})
    end
  end

  def workspace
    job.workspace
  end

  def create_import
    import_params = {
        :user => workspace.owner,
        :to_table => destination_dataset_name,
        :truncate => truncate,
        :sample_count => row_limit,
        :new_table => new_table_import?
    }
    import = WorkspaceImport.new(import_params)
    import.workspace = workspace
    import.source_dataset = source_dataset
    import.save!
    import
  end

  def run_import(import_id)
    ImportExecutor.run import_id
  end

  def new_table_import?
    !destination_id
  end

  def set_destination_id!
    self.destination_id = workspace.sandbox.datasets.find_by_name(destination_name).id
    self.destination_name = nil
    save!
  end
end