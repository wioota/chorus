class Job < ActiveRecord::Base
  include SoftDelete

  attr_accessible :enabled, :name, :frequency, :next_run, :last_run

  belongs_to :workspace

  frequencies = %w( hourly daily weekly monthly demand custom )
  validates :frequency, :presence => true, :inclusion => {:in => frequencies }
  validates_presence_of :next_run
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:workspace_id, :deleted_at]
end
