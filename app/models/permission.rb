class Permission < ActiveRecord::Base
  attr_accessible :class_id, :permission_mask

  belongs_to :role
end