module DataSources
  class WorkspaceDetailsController < ApplicationController
    def show
      gpdb_instance = GpdbInstance.find(params[:data_source_id])
      present gpdb_instance, :presenter_options => {:presenter_class => :GpdbInstanceWorkspaceDetailPresenter}
    end
  end
end