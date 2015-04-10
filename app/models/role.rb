class Role < ActiveRecord::Base
  attr_accessible :name, :description

  has_and_belongs_to_many :users
  has_and_belongs_to_many :groups
  has_many :permissions
  has_many :chorus_object_roles
  has_many :chorus_objects, :through => :chorus_object_roles
end