class AssociatedDataset < ActiveRecord::Base
  include SoftDelete

  validates_uniqueness_of :dataset_id, :scope => [:workspace_id, :deleted_at]
  validates_presence_of :workspace_id, :dataset_id

  belongs_to :workspace
  belongs_to :dataset
end
