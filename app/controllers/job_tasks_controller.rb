class JobTasksController < ApplicationController
  def create
    authorize! :can_edit_sub_objects, workspace

    job = Job.find(params[:job_id])
    task = JobTask.assemble!(params[:job_task], job)

    present task, :status => :created
  end

  def destroy
    authorize! :can_edit_sub_objects, workspace

    JobTask.find(params[:id]).destroy

    head :ok
  end

  def update
    authorize! :can_edit_sub_objects, workspace

    job_task = JobTask.find(params[:id])
    job_task.update_attributes(params[:job_task])

    present job_task
  end

  protected

  def workspace
    @workspace ||= Workspace.find(params[:workspace_id])
  end
end