class ChorusClass < ActiveRecord::Base
  attr_accessible :name, :description, :parent_class_id, :parent_class_name

  has_many :chorus_objects
  has_many :operations
  has_many :permissions
end
