class Job < ActiveRecord::Base
  include SoftDelete

  attr_accessible :enabled, :name, :next_run, :last_run, :interval_unit, :interval_value, :end_run, :time_zone
  cattr_reader :valid_interval_units; @@valid_interval_units = %w(hours days weeks months on_demand)

  belongs_to :workspace
  has_many :job_tasks

  validates :interval_unit, :presence => true, :inclusion => {:in => valid_interval_units }
  validates_presence_of :interval_value
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:workspace_id, :deleted_at]

  def self.order_by(column_name)
    if column_name.blank? || column_name == "name"
      return order("lower(name), id")
    end

    if %w(next_run).include?(column_name)
      order("#{column_name} desc")
    end
  end
end
