class JobsController < ApplicationController
  def index
    workspace = Workspace.find(params[:workspace_id])
    authorize! :show, workspace

    jobs = workspace.jobs.order_by(params[:order])

    present paginate(jobs)
  end

  def create
    Job.create! params[:job]
    head :created
  end
end