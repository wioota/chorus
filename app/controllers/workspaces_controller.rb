class WorkspacesController < ApplicationController
  wrap_parameters :exclude => []

  before_filter :demo_mode_filter, :only => [:create, :destroy]

  def index
    if params[:user_id]
      user = User.find(params[:user_id])
      workspaces = user.workspaces.workspaces_for(current_user)
    else
      workspaces = Workspace.workspaces_for(current_user)
    end

    workspaces = workspaces.active if params[:active]
    succinct = params[:succinct] == 'true'
    # Prakash 1/22. Needed to separate namespaces for home page and workspaces page. The JSON data
    # generated for two pages is different. This needs to be fixed in future.

    @namespace = succinct ? 'home:workspaces' : 'workspaces:workspaces'
    if params[:get_options] == 'most_active'
      available_workspaces = workspaces.map(&:id)
      results = []

      if (available_workspaces.nil? || available_workspaces.count == 0 )
        present paginate(results),
                :presenter_options => {}
      else
        top_workspace_ids = Events::Base.select('workspace_id, count(*) as event_count')
                                        .group(:workspace_id)
                                        .where('workspace_id IN (' + available_workspaces.join(',') + ')')
                                        .order('event_count desc')
                                        .limit(10)
                            .map(&:workspace_id)

        @workspaces = workspaces.where('id IN (' + top_workspace_ids.join(',') + ')')
                            .includes(succinct ? [:owner] : Workspace.eager_load_associations)
                            .order("lower(name) ASC, id")

        present paginate(@workspaces),
           :presenter_options => {
               :show_latest_comments => (params[:show_latest_comments] == 'true'),
              :succinct => succinct, :cached => true, :namespace => @namespace
        }

      end
    else

      @workspaces = workspaces.includes(succinct ? [:owner] : Workspace.eager_load_associations)
                          .order("lower(name) ASC, id")

      present paginate(@workspaces),
             :presenter_options => {
                 :show_latest_comments => (params[:show_latest_comments] == 'true'),
                 :succinct => succinct, :cached => true, :namespace => @namespace
             }

    end

  end

  def create
    workspace = Workspace.create_for_user(current_user, params[:workspace])
    present workspace, :status => :created
  end


  def show
    workspace = Workspace.find(params[:id])
    authorize! :show, workspace
    # use the cached version of "workspaces:workspaces" namespace.
    present workspace, :presenter_options => {:show_latest_comments => params[:show_latest_comments] == 'true',:cached => true, :namespace => 'workspaces:workspaces' }
  end

  def update
    workspace = Workspace.find(params[:id])

    attributes = params[:workspace]
    attributes[:archiver] = current_user if (attributes[:archived] && !workspace.archived?)
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

    if workspace.archived_changed?
      workspace.archived? ?
          Events::WorkspaceArchived.by(current_user).add(:workspace => workspace) :
          Events::WorkspaceUnarchived.by(current_user).add(:workspace => workspace)
    end

    if workspace.show_sandbox_datasets_changed?
      workspace.show_sandbox_datasets? ?
          Events::WorkspaceToShowSandboxDatasets.by(current_user).add(:workspace => workspace) :
          Events::WorkspaceToNoLongerShowSandboxDatasets.by(current_user).add(:workspace => workspace)
    end

    if workspace.project_status_changed? || workspace.project_status_reason_changed?
      Events::ProjectStatusChanged.by(current_user).add(:workspace => workspace)
    end
  end
end

