require 'allowy'
require 'hdfs_data_source_access'

class HdfsDataSourcesController < ApplicationController
  def create
    instance = Hdfs::DataSourceRegistrar.create!(params[:hdfs_data_source], current_user)
    QC.enqueue_if_not_queued("HdfsDataSource.refresh", instance.id)
    present instance, :status => :created
  end

  def index
    present paginate HdfsDataSource.scoped
  end

  def show
    present HdfsDataSource.find(params[:id])
  end

  def update
    hdfs_data_source = HdfsDataSource.find(params[:id])
    authorize! :edit, hdfs_data_source

    hdfs_data_source = Hdfs::DataSourceRegistrar.update!(hdfs_data_source.id, params[:hdfs_data_source], current_user)
    present hdfs_data_source
  end
end
