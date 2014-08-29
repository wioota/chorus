class DashboardItem < ActiveRecord::Base

  ALLOWED_MODULES = %w(SiteSnapshot WorkspaceActivity ActivityStream ProjectCardList)
  DEFAULT_MODULES = ALLOWED_MODULES.first(3)

  attr_accessible :name, :location

  validates_inclusion_of :name, :in => ALLOWED_MODULES
end
