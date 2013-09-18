class Milestone < ActiveRecord::Base
  STATUSES = ['planned', 'achieved']

  belongs_to :workspace
  attr_accessible :name, :status, :target_date

  validates_presence_of :name, :status, :target_date, :workspace
  validates_inclusion_of :status, :in => STATUSES

  after_save :update_counter_cache
  after_destroy :update_counter_cache

  before_validation :set_status_planned, :on => :create

  private

  def update_counter_cache
    workspace.update_column(:milestones_count, workspace.milestones.count)
    workspace.update_column(:milestones_achieved_count, workspace.milestones.where(status: 'achieved').count)
  end

  def set_status_planned
    self.status = 'planned'
  end
end
