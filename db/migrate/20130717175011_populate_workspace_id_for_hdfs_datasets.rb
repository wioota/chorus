class PopulateWorkspaceIdForHdfsDatasets < ActiveRecord::Migration
  class Dataset < ActiveRecord::Base; end
  class AssociatedDatabase < ActiveRecord::Base; end

  def up
    Dataset.where(type: 'HdfsDataset').find_each do |dataset|
      associations = AssociatedDataset.where(dataset_id: dataset.id)
      if associations.present?
        dataset.update_attribute(:workspace_id, associations.first.workspace.id)
        dataset.save!
        associations.destroy_all
      end
    end
  end

  def down
  end
end
