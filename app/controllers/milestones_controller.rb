class MilestonesController < ApplicationController
  before_filter :apply_timezone, only: [:create, :update]

  def index
    authorize! :show, workspace

    milestones = workspace.milestones.order(:target_date)

    present paginate(milestones), :presenter_options => {:list_view => true}
  end

  protected

  def workspace
    @workspace ||= Workspace.find(params[:workspace_id])
  end

end