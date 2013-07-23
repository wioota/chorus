class Job < ActiveRecord::Base
  include SoftDelete

  attr_accessible :enabled, :name, :frequency, :next_run, :last_run

  belongs_to :workspace

  frequencies = %w( hourly daily weekly monthly demand custom )
  validates :frequency, :presence => true, :inclusion => {:in => frequencies }
  validates_presence_of :next_run
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
