class Milestone < ActiveRecord::Base
  STATES = ['planned', 'achieved']

  belongs_to :workspace
  attr_accessible :name, :state, :target_date

  validates_presence_of :name, :state, :target_date, :workspace
  validates_inclusion_of :state, :in => STATES

  after_save :update_counter_cache
  after_destroy :update_counter_cache

  before_validation :set_state_planned, :on => :create

  private

  def update_counter_cache
    workspace.update_column(:milestones_count, workspace.milestones.count)
    workspace.update_column(:milestones_achieved_count, workspace.milestones.where(state: 'achieved').count)
  end

  def set_state_planned
    self.state = 'planned'
  end
end
