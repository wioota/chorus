class JobTask < ActiveRecord::Base
  include SoftDelete
  attr_accessible :index, :type, :job, :status, :payload_result_id

  belongs_to :job
  validates_presence_of :job_id

  before_create :provide_index
  validates :type, :presence => true
  after_destroy :compact_indices

  JobTaskFailure = Class.new(StandardError)

  def self.assemble!(params, job)
    klass = "#{params[:action].camelize}Task".constantize
    task = klass.new(params)
    task.job = job
    task.attach_payload params
    task.save!
    task
  end

  def action
    type.gsub(/Task\z/, '').underscore
  end

  def execute
    raise NotImplementedError
  end

  def build_task_name
    raise NotImplementedError
  end

  private

  def provide_index
    self.index = job.next_task_index
  end

  def compact_indices
    job.compact_indices
  end
end
