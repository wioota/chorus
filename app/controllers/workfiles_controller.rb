require 'will_paginate/array'

class WorkfilesController < ApplicationController
  wrap_parameters :workfile
  include DataSourceAuth

  before_filter :execution_locations_to_array, :only => [:create, :update]

  def show
    workfile = Workfile.find(params[:id])
    authorize! :show, workfile.workspace

    if params[:connect].present?
      authorize_data_sources_access workfile
      workfile.attempt_data_source_connection
    end

    present workfile, :presenter_options => {:contents => true, :workfile_as_latest_version => true}
  end

  def create
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace

    workfile = Workfile.build_for(params[:workfile].merge(:workspace => workspace, :owner => current_user))
    workfile.update_from_params!(params[:workfile])

    present workfile, presenter_options: {:workfile_as_latest_version => true}, status: :created
  end

  def update
    workfile = Workfile.find(params[:id])
    authorize! :can_edit_sub_objects, workfile.workspace
    execution_schema = params[:workfile][:execution_schema]

    if execution_schema && execution_schema[:id]
      schema = GpdbSchema.find(execution_schema[:id])
      params[:workfile][:execution_schema] = schema
    end

    if params[:workfile][:action] == "run"
      workfile.run_now(current_user)
    elsif params[:workfile][:action] == "stop"
      workfile.stop_now(current_user)
    else
      workfile.assign_attributes(params[:workfile])
      workfile.update_from_params!(params[:workfile])
    end

    present workfile, :presenter_options => {:include_execution_schema => true}
  end

  def index
    workspace = Workspace.find(params[:workspace_id])
    authorize! :show, workspace

    workfiles = workspace.filtered_workfiles(params)

    present paginate(workfiles), :presenter_options => {:workfile_as_latest_version => true, :list_view => true}
  end

  def destroy
    workfile = Workfile.find(params[:id])
    authorize! :can_edit_sub_objects, workfile.workspace

    workfile.destroy
    render :json => {}
  end

  private

  def execution_locations_to_array
    params[:workfile][:execution_locations] = params[:workfile][:execution_locations].values if params[:workfile][:execution_locations]
  end
end
