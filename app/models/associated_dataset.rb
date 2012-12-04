class AssociatedDataset < ActiveRecord::Base
  include SoftDelete

  validates_presence_of :workspace, :dataset
  validates_uniqueness_of :dataset_id, :scope => [:workspace_id, :deleted_at]
  validate :dataset_not_chorus_view

  belongs_to :workspace
  belongs_to :dataset

  private

  def dataset_not_chorus_view
    if dataset.is_a? ChorusView
      errors.add(:dataset, :invalid_type)
    end
  end
end
