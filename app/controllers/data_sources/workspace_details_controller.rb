module DataSources
  class WorkspaceDetailsController < ApplicationController
    def show
      gpdb_data_source = GpdbDataSource.find(params[:data_source_id])
      present gpdb_data_source, :presenter_options => {:presenter_class => :GpdbDataSourceWorkspaceDetailPresenter}
    end
  end
end