class JobsController < ApplicationController
  before_filter :apply_next_run_timezone, only: [:create, :update]

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

  def destroy
    authorize! :can_edit_sub_objects, workspace

    Job.find(params[:id]).destroy

    head :ok
  end

  protected

  def apply_next_run_timezone
    params[:job][:next_run] = ActiveSupport::TimeZone[params[:job][:time_zone]].parse(DateTime.parse(params[:job][:next_run]).asctime)
  end

  def workspace
    @workspace ||= Workspace.find(params[:workspace_id])
  end

end