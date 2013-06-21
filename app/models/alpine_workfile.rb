class AlpineWorkfile < Workfile
  TooManyDataBases = Class.new(StandardError)

  has_additional_data :dataset_ids

  before_validation { self.content_type ='work_flow' }
  before_validation { self.execution_location = datasets.first.database unless datasets.empty? }
  validates_presence_of :execution_location
  validates_with AlpineWorkfileValidator

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

  def notify_alpine_of_deletion
    # This will only work in development mode if you have alpine running locally and you have
    # config.threadsafe! or config.allow_concurrency = true in your config/environments/development.rb
    # Otherwise, this will time out.
    Alpine::API.delete_work_flow(self)
  end
end