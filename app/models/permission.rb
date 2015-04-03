class Permission < ActiveRecord::Base
  attr_accessible :permissions_mask

  validates_uniqueness_of :role_id, :scope => :chorus_class_id
  belongs_to :role
  belongs_to :chorus_class
end