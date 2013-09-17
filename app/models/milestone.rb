class Milestone < ActiveRecord::Base
  STATUSES = ['planned', 'achieved']

  belongs_to :workspace
  attr_accessible :name, :status, :target_date

  validates_presence_of :name, :status, :target_date, :workspace
  validates_inclusion_of :status, :in => STATUSES
end
