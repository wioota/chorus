class MilestonesController < ApplicationController
  def index
    authorize! :show, workspace

    milestones = workspace.milestones.order(:target_date)

    present paginate(milestones), :presenter_options => {:list_view => true}
  end

  def create
    authorize! :can_edit_sub_objects, workspace

    milestone = workspace.milestones.create params[:milestone]

    present milestone, :status => :created
  end

  def destroy
    authorize! :can_edit_sub_objects, workspace

    Milestone.find(params[:id]).destroy

    head :ok
  end

  protected

  def workspace
    @workspace ||= Workspace.find(params[:workspace_id])
  end

end