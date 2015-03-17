class Scope < ActiveRecord::Base
  attr_accessible :name, :description

  validates :name, :presence => true

  has_many :chorus_objects
  belongs_to :group
end