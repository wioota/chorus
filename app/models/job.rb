class Job < ActiveRecord::Base
  include SoftDelete

  attr_accessible :enabled, :name

  belongs_to :workspace

  validates_uniqueness_of :name, :scope => [:workspace_id, :deleted_at]
end
