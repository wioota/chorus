class AlpineWorkfile < Workfile
  TooManyDataBases = Class.new(StandardError)

  has_additional_data :dataset_ids, :hdfs_entry_ids

  before_validation { self.content_type ='work_flow' }
  before_validation :determine_execution_location
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
    update_execution_location(params)
    update_file_name(params)

    Workfile.transaction do
      notify_alpine_of_upload(scoop_file_from(params)) if (save! && !params[:file_name])
    end
  rescue Net::ProtocolError, SocketError, Errno::ECONNREFUSED, TimeoutError => e
    raise ApiValidationError.new(:base, :alpine_connection_error)
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

  def update_file_name(params)
    self.resolve_name_conflicts = !params[:file_name]
    self.file_name = scoop_file_name(params) if params[:versions_attributes]
  end

  def scoop_file_name(params)
    full_name = params[:versions_attributes]["0"][:contents].original_filename
    full_name.gsub('.afm', '')
  end

  def scoop_file_from(params)
    params[:versions_attributes]['0'][:contents].read
  end

  def update_execution_location(params)
    self.execution_location = GpdbDatabase.find(params[:database_id]) unless params[:database_id].to_s == ""
    self.execution_location = HdfsDataSource.find(params[:hdfs_data_source_id]) unless params[:hdfs_data_source_id].to_s == ""

    if execution_location_id_changed? || execution_location_type_changed?
      self.hdfs_entry_ids = nil
      self.dataset_ids = nil
    end
  end

  def determine_execution_location
    self.execution_location = datasets.first.database unless datasets.empty?
    self.execution_location = hdfs_entries.first.hdfs_data_source unless hdfs_entries.empty?
  end

  def notify_alpine_of_deletion
    # This will only work in development mode if you have alpine running locally and you have
    # config.threadsafe! or config.allow_concurrency = true in your config/environments/development.rb
    # Otherwise, this will time out.
    Alpine::API.delete_work_flow(self)
  end

  def notify_alpine_of_upload(file_contents)
    Alpine::API.create_work_flow(self, file_contents)
  end

  def ensure_active_workspace
    self.errors[:workspace] << :ARCHIVED if workspace && workspace.archived?
  end
end