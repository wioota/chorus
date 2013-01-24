class WorkspacesController < ApplicationController
  wrap_parameters :exclude => []
  def index
    if params[:user_id]
      user = User.find(params[:user_id])
      workspaces = user.workspaces.workspaces_for(current_user)
    else
      workspaces = Workspace.workspaces_for(current_user)
    end
    workspaces = workspaces.active if params[:active]
    present paginate(workspaces.includes([:owner, :archiver, {:sandbox => {:database => :gpdb_data_source}}]).order("lower(name) ASC")), :presenter_options => {:show_latest_comments => params[:show_latest_comments] == 'true'}
  end

  def create
    workspace = current_user.owned_workspaces.build(params[:workspace])
    Workspace.transaction do
      workspace.save!
      workspace.public ?
          Events::PublicWorkspaceCreated.by(current_user).add(:workspace => workspace) :
          Events::PrivateWorkspaceCreated.by(current_user).add(:workspace => workspace)
    end
    present workspace, :status => :created
  end

  def show
    workspace = Workspace.find(params[:id])
    authorize! :show, workspace
    present workspace, :presenter_options => {:show_latest_comments => params[:show_latest_comments] == 'true'}
  end

  def update
    workspace = Workspace.find(params[:id])
    authorize! :update, workspace

    original_archived = workspace.archived?.to_s
    attributes = params[:workspace]
    attributes[:archiver] = current_user if attributes[:archived] == 'true'
    workspace.attributes = attributes

    create_workspace_events(workspace, original_archived)
    workspace.save!
    present workspace
  end

  def destroy
    workspace = Workspace.find(params[:id])
    authorize!(:destroy, workspace)
    Events::WorkspaceDeleted.by(current_user).add(:workspace => workspace)
    workspace.destroy

    render :json => {}
  end

  private

  def create_workspace_events(workspace, original_archived)
    if workspace.public_changed?
      workspace.public ?
          Events::WorkspaceMakePublic.by(current_user).add(:workspace => workspace) :
          Events::WorkspaceMakePrivate.by(current_user).add(:workspace => workspace)
    end
    if params[:workspace][:archived].present? && params[:workspace][:archived] != original_archived
      workspace.archived? ?
          Events::WorkspaceArchived.by(current_user).add(:workspace => workspace) :
          Events::WorkspaceUnarchived.by(current_user).add(:workspace => workspace)
    end
  end
end

