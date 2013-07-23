class Job < ActiveRecord::Base
  belongs_to :workspace
  attr_accessible :enabled, :name
end
