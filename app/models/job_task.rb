class JobTask < ActiveRecord::Base
  include SoftDelete
  ACTIONS = %w( import_source_data run_work_flow run_sql_file )

  @@actions = Hash[
    'import_source_data' => 'ImportSourceDataTask'
  ]

  attr_accessible :index, :action

  belongs_to :job

  validates :index, :presence => true, :uniqueness => {:scope => [:job_id, :deleted_at]}
  validates :action, :presence => true, :inclusion => {:in => ACTIONS }
  validates_presence_of :job

  serialize :additional_data, JsonHashSerializer

  def self.create_for_action!(params)
    job_task_params = params[:job_task]
    job = Job.find(params[:job_id])
    job_task_params[:index] = (job.job_tasks.order(:index).last.try(:index) || 0) + 1
    klass = @@actions.fetch(job_task_params[:action], 'JobTask').constantize
    klass.assemble!(job_task_params, job)
  end

end
