class Job < ActiveRecord::Base
  include SoftDelete

  STATUSES = %w(enqueued running idle)
  VALID_INTERVAL_UNITS = %w(hours days weeks months on_demand)

  attr_accessible :enabled, :name, :next_run, :last_run, :interval_unit, :interval_value, :end_run, :time_zone, :status

  belongs_to :workspace
  has_many :job_tasks

  validates :interval_unit, :presence => true, :inclusion => {:in => VALID_INTERVAL_UNITS }
  validates :status, :presence => true, :inclusion => {:in => STATUSES }
  validates_presence_of :interval_value
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:workspace_id, :deleted_at]

  scope :ready_to_run, -> { where(enabled: true).where('next_run <= ?', Time.current) }

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
    self.next_run = frequency.since(next_run)
    self.last_run = Time.current
    self.disable! if next_run > end_run
    self.status = 'running'
    save!
    job_tasks.order("index ASC").each(&:execute)
  end

  def frequency
    interval_value.send(interval_unit) unless on_demand?
  end

  def enable!
    self.enabled = true
    save!
  end

  def disable!
    self.enabled = false
    save!
  end

  private

  def on_demand?
    interval_unit == 'on_demand'
  end
end
