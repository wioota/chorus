class Permission < ActiveRecord::Base
  attr_accessible :class_id, :permissions_mask

  belongs_to :role
end