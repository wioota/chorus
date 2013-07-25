class JobsController < ApplicationController

  def index
    authorize! :show, workspace

    jobs = workspace.jobs.order_by(params[:order])

    present paginate(jobs), :presenter_options => {:list_view => true}
  end

  def show
    authorize! :show, workspace

    job = workspace.jobs.find(params[:id])

    present job
  end

  def create

    authorize! :can_edit_sub_objects, workspace

    job = Job.create!(params[:job])
    workspace.jobs << job

    present job, :status => :created
  end

  def update

    authorize! :can_edit_sub_objects, workspace

    job = workspace.jobs.find(params[:id])
    job.update_attributes(params[:job])

    present job, :status => :ok
  end

  protected

  def workspace
    @workspace ||= Workspace.find(params[:workspace_id])
  end

end