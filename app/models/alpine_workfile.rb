class AlpineWorkfile < Workfile
  TooManyDataBases = Class.new(StandardError)

  has_additional_data :dataset_ids, :hdfs_entry_ids

  before_validation { self.content_type ='work_flow' }
  before_validation { self.execution_location = datasets.first.database unless datasets.empty? }
  before_validation { self.execution_location = hdfs_entries.first.hdfs_data_source unless hdfs_entries.empty? }
  validates_presence_of :execution_location
  validates_with AlpineWorkfileValidator
  validate :ensure_active_workspace, :on => :create

  after_destroy :notify_alpine_of_deletion

  def entity_subtype
    'alpine'
  end

  def attempt_data_source_connection
    data_source.attempt_connection(current_user)
  end

  def data_source
    execution_location.data_source
  end

  def update_from_params!(params)
    self.execution_location = GpdbDatabase.find(params[:database_id]) if params[:database_id]
    self.execution_location = HdfsDataSource.find(params[:hdfs_data_source_id]) if params[:hdfs_data_source_id]
    save!
  end

  def datasets
    @datasets ||= Dataset.where(:id => dataset_ids)
  end

  def hdfs_entries
    @hdfs_entries ||= HdfsEntry.where(:id => hdfs_entry_ids)
  end

  def create_new_version(user, params)
    Events::WorkFlowUpgradedVersion.by(user).add(
      :workfile => self,
      :workspace => workspace,
      :commit_message => params[:commit_message]
    )
  end

  private

  def notify_alpine_of_deletion
    # This will only work in development mode if you have alpine running locally and you have
    # config.threadsafe! or config.allow_concurrency = true in your config/environments/development.rb
    # Otherwise, this will time out.
    Alpine::API.delete_work_flow(self)
  end

  def ensure_active_workspace
    self.errors[:workspace] << :ARCHIVED if workspace && workspace.archived?
  end
end