class JobsController < ApplicationController
  def index
    workspace = Workspace.find(params[:workspace_id])
    authorize! :show, workspace

    jobs = workspace.jobs.order_by(params[:order])

    present paginate(jobs), :presenter_options => {:list_view => true}
  end

  def show
    job = Job.find(params[:id])
    workspace = job.workspace
    authorize! :show, workspace

    present job
  end

  def create
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace

    job = Job.create!(params[:job])
    workspace.jobs << job

    present job, :status => :created
  end
end