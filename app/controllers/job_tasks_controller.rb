class JobTasksController < ApplicationController
  def create
    authorize! :can_edit_sub_objects, workspace

    job_task = JobTask.create_for_action!(params)
    present job_task, :status => :created
  end

  protected

  def workspace
    @workspace ||= Workspace.find(params[:workspace_id])
  end
end