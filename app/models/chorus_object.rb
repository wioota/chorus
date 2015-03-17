class ChorusObject < ActiveRecord::Base
  attr_accessible :class_id, :instance_id, :parent_class_id, :parent_class_name, :permission_mask

  belongs_to :scope
end