require 'will_paginate/array'

class WorkfilesController < ApplicationController
  include DataSourceAuth

  def show
    workfile = Workfile.find(params[:id])
    authorize! :show, workfile.workspace

    if params[:connect].present?
      authorize_data_source_access workfile
      workfile.attempt_data_source_connection
    end

    present workfile, :presenter_options => {:contents => true, :workfile_as_latest_version => true}
  end

  def create
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace

    workfile_params = params[:workfile]
    workfile = Workfile.build_for(workfile_params.merge(:workspace => workspace, :owner => current_user))
    is_upload = !workfile_params[:file_name]
    is_svg = workfile_params[:svg_data]
    workfile.resolve_name_conflicts = (is_svg || is_upload)
    workfile.execution_location = GpdbDatabase.find(workfile_params[:database_id]) if workfile_params[:database_id]
    workfile.execution_location = HdfsDataSource.find(workfile_params[:hdfs_data_source_id]) if workfile_params[:hdfs_data_source_id]
    workfile.save!

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

    workfile.update_attributes!(params[:workfile])
    present workfile, :presenter_options => {:include_execution_schema => true}
  end

  def index
    workspace = Workspace.find(params[:workspace_id])
    authorize! :show, workspace

    workfiles = workspace.workfiles.order_by(params[:order]).includes(:latest_workfile_version)

    if params.has_key?(:file_type)
      workfiles = workfiles.with_file_type(params[:file_type])
    end

    workfiles = workfiles.includes(Workfile.eager_load_associations)

    present paginate(workfiles), :presenter_options => {:workfile_as_latest_version => true, :list_view => true}
  end


  def destroy
    workfile = Workfile.find(params[:id])
    authorize! :can_edit_sub_objects, workfile.workspace

    workfile.destroy
    render :json => {}
  end
end
