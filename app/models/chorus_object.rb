class ChorusObject < ActiveRecord::Base
  attr_accessible :class_id, :instance_id, :parent_class_id, :parent_class_name, :permission_mask

  belongs_to :chorus_class
  belongs_to :scope
  has_many :chorus_object_roles
  has_many :roles, :through => :chorus_object_roles

  def referenced_object
    actual_class = chorus_class.name.constantize
    actual_object = actual_class.find(instance_id)
  end
end