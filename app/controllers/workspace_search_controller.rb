class WorkspaceSearchController < ApplicationController

  def show
    workspace = Workspace.find(params[:workspace_id])
    authorize! :show, workspace
    present WorkspaceSearch.new(current_user, params)
  end
end