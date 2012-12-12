class Tagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :entity, :polymorphic => true

  validates :tag, :presence => true
  validates :tag_id, :uniqueness => { :scope => [:entity_id, :entity_type] }
  validates :entity, :presence => true
end