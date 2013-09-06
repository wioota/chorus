require 'set'

class AlpineWorkfile < Workfile
  TooManyDataBases = Class.new(StandardError)

  has_additional_data :dataset_ids
  has_many :workfile_execution_locations, foreign_key: :workfile_id

  before_validation { self.content_type ='work_flow' }
  after_create :determine_execution_location
  validates_with AlpineWorkfileValidator
  validate :ensure_active_workspace, :on => :create

  after_destroy :notify_alpine_of_deletion

  def execution_locations
    workfile_execution_locations.map(&:execution_location)
  end

  def entity_subtype
    'alpine'
  end

  def attempt_data_source_connection
    data_sources.each do |ds|
      ds.attempt_connection(current_user)
    end
  end

  def data_sources
    execution_locations.map(&:data_source)
  end

  def update_from_params!(params)
    update_execution_location(params) if params[:execution_locations].present?
    update_file_name(params)
    Workfile.transaction do
      save!
      notify_alpine_of_upload(scoop_file_from(params)) if !params[:file_name]
    end
  rescue Net::ProtocolError, SocketError, Errno::ECONNREFUSED, TimeoutError => e
    raise ApiValidationError.new(:base, :alpine_connection_error)
  end

  def datasets
    @datasets ||= Dataset.where(:id => dataset_ids)
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
    workfile_execution_locations.destroy_all

    params[:execution_locations].each do |location|
      source = if location[:entity_type] == 'gpdb_database'
        GpdbDatabase.find location[:id]
      else
        HdfsDataSource.find location[:id]
      end

      workfile_execution_locations.build(:execution_location => source)
    end
  end

  def determine_execution_location
    unless datasets.empty?
      sources = datasets.map(&:execution_location)

      sources.uniq.each do |source|
        workfile_execution_locations.create!(:execution_location => source)
      end
    end
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