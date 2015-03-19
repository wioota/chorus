class Operation < ActiveRecord::Base
  attr_accessible :name, :description

  belongs_to :chorus_class

  validates :name, :presence => true
end
