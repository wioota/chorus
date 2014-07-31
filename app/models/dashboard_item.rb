class DashboardItem < ActiveRecord::Base

  ALLOWED_MODULES = DEFAULT_MODULES = %w(Module1 Module2 Module3)

  attr_accessible :name, :location

  validates_inclusion_of :name, :in => ALLOWED_MODULES
end
