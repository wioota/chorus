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
    succinct = params[:succinct] == 'true'
    present paginate(workspaces.includes(succinct ? [] : Workspace.eager_load_associations).order("lower(name) ASC, id")),
            :presenter_options => {:show_latest_comments => params[:show_latest_comments] == 'true', :succinct => succinct}
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

    attributes = params[:workspace]
    attributes[:archiver] = current_user if attributes[:archived] == 'true'
    workspace.attributes = attributes

    authorize! :update, workspace

    create_workspace_events(workspace) if workspace.valid?

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

  def create_workspace_events(workspace)
    if workspace.public_changed?
      workspace.public? ?
          Events::WorkspaceMakePublic.by(current_user).add(:workspace => workspace) :
          Events::WorkspaceMakePrivate.by(current_user).add(:workspace => workspace)
    end

    if workspace.archived_at_changed?
      workspace.archived? ?
          Events::WorkspaceArchived.by(current_user).add(:workspace => workspace) :
          Events::WorkspaceUnarchived.by(current_user).add(:workspace => workspace)
    end

    if workspace.show_sandbox_datasets_changed?
      workspace.show_sandbox_datasets? ?
          Events::WorkspaceToShowSandboxDatasets.by(current_user).add(:workspace => workspace) :
          Events::WorkspaceToNoLongerShowSandboxDatasets.by(current_user).add(:workspace => workspace)
    end
  end
end

