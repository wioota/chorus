class HdfsDatasetsController < ApplicationController
  wrap_parameters :hdfs_dataset, :include => [:name, :file_mask, :data_source_id, :workspace_id]

  def create
    data_source = HdfsDataSource.find params[:hdfs_dataset].delete(:data_source_id)
    workspace   = Workspace.find params[:hdfs_dataset].delete(:workspace)[:id]

    dataset     = HdfsDataset.assemble!(params[:hdfs_dataset], data_source, workspace, current_user)

    present dataset, :status => :created
  end

  def update
    dataset = Dataset.find(params[:id])
    dataset.update_attributes!(params[:hdfs_dataset])
    present dataset
  end
end