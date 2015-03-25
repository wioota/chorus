class Permission < ActiveRecord::Base
  attr_accessible :permissions_mask

  belongs_to :role
  belongs_to :chorus_class
end