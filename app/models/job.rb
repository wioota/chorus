class Job < ActiveRecord::Base
  include SoftDelete

  STATUSES = %w(enqueued running idle)
  VALID_INTERVAL_UNITS = %w(hours days weeks months on_demand)

  attr_accessible :enabled, :name, :next_run, :last_run, :interval_unit, :interval_value, :end_run, :time_zone, :status

  belongs_to :workspace
  has_many :job_tasks, :order => :index

  validates :interval_unit, :presence => true, :inclusion => {:in => VALID_INTERVAL_UNITS }
  validates :status, :presence => true, :inclusion => {:in => STATUSES }
  validates_presence_of :interval_value
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:workspace_id, :deleted_at]
  validate :next_run_not_in_past, :if => Proc.new { |job| job.changed.include?('next_run') }

  scope :ready_to_run, -> { where(enabled: true).where(status: 'idle').where('next_run <= ?', Time.current).order(:next_run) }

  before_validation :disable_expiring

  def self.order_by(column_name)
    if column_name.blank? || column_name == "name"
      return order("lower(name), id")
    end

    if %w(next_run).include?(column_name)
      order("#{column_name} desc")
    end
  end

  def self.run(id)
    find(id).run
  end

  def enqueue
    QC.default_queue.enqueue_if_not_queued("Job.run", id)
    self.status = 'enqueued'
    save!
  end

  def run
    ensure_next_run_is_in_the_future
    self.last_run = Time.current
    self.disable! if expiring?
    self.status = 'running'
    save!
    execute_tasks
    job_succeeded
  rescue JobTask::JobTaskFailure
    job_failed
  ensure
    idle!
  end

  def frequency
    interval_value.send(interval_unit) unless on_demand?
  end

  def enable!
    ensure_next_run_is_in_the_future
    self.enabled = true
    save!
  end

  def disable!
    self.enabled = false
    save!
  end

  def next_task_index
    (job_tasks.last.try(:index) || 0) + 1
  end

  def compact_indices
    job_tasks.each_with_index do |task, index|
      task.update_attribute(:index, index + 1)
    end
  end

  private

  def ensure_next_run_is_in_the_future
    if next_run
      while next_run < Time.current
        increment_next_run
      end
    end
  end

  def increment_next_run
    self.next_run = frequency.since(next_run)
  end

  def disable_expiring
    self.enabled = false if expiring?
    true
  end

  def next_run_not_in_past
    if next_run && next_run < 1.minutes.ago
      errors.add(:job, :NEXT_RUN_IN_PAST)
    end
  end

  def job_succeeded
    Events::JobSucceeded.by(workspace.owner).add(:job => self, :workspace => workspace)
  end

  def job_failed
    Events::JobFailed.by(workspace.owner).add(:job => self, :workspace => workspace)
  end

  def execute_tasks
    job_tasks.each(&:execute)
  end

  def on_demand?
    interval_unit == 'on_demand'
  end

  def expiring?
    on_demand? ? false : (end_run && next_run > end_run.to_date)
  end

  def idle!
    self.status = 'idle'
    save!
  end
end
