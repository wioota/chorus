class Group < ActiveRecord::Base
  attr_accessible :name, :description

  validates :name, :presence => true

  has_and_belongs_to_many :users
  has_and_belongs_to_many :roles
  has_one :scope
end