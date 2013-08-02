class JobTask < ActiveRecord::Base
  include SoftDelete
  ACTIONS = %w( import_source_data run_work_flow run_sql_file )

  @@actions = Hash[
    'import_source_data' => 'ImportSourceDataTask',
    'run_work_flow' => 'RunWorkFlowTask'
  ]

  attr_accessible :index, :action

  belongs_to :job

  before_validation :set_index

  validates :index, :presence => true, :uniqueness => {:scope => [:job_id, :deleted_at]}
  validates :action, :presence => true, :inclusion => {:in => ACTIONS }
  validates_presence_of :job

  serialize :additional_data, JsonHashSerializer

  JobTaskFailure = Class.new(StandardError)

  def self.create_for_action!(params)
    job_task_params = params[:job_task]
    job = Job.find(params[:job_id])
    klass = @@actions[job_task_params[:action]].constantize
    klass.assemble!(job_task_params, job)
  end

  def execute
    raise NotImplementedError
  end

  private

  def set_index
    self.index = index || job.next_task_index
  end
end
