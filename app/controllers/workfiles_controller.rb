require 'will_paginate/array'

class WorkfilesController < ApplicationController
  wrap_parameters :workfile, :exclude => []

  def show
    workfile = Workfile.find(params[:id])
    authorize! :show, workfile.workspace
    present workfile, :presenter_options => { :contents => true, :workfile_as_latest_version => true }
  end

  def create
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace

    present create_workfile(workspace), :presenter_options => { :workfile_as_latest_version => true }
  end

  def index
    workspace = Workspace.find(params[:workspace_id])
    authorize! :show, workspace

    finder = Workfile.order(workfile_sort(params[:order])).includes(:latest_workfile_version)

    if params.has_key?(:file_type)
      workfiles = finder.find_all_by_workspace_id_and_content_type(workspace, params[:file_type].downcase)
    else
      workfiles = finder.find_all_by_workspace_id(workspace)
    end

    present paginate(workfiles), :presenter_options => { :workfile_as_latest_version => true }
  end

  def destroy
    workfile = Workfile.find(params[:id])
    authorize! :can_edit_sub_objects, workfile.workspace

    workfile.destroy
    render :json => {}
  end

  private

  def workfile_sort(column_name)
    if column_name.blank? || column_name == "file_name"
      "lower(file_name)"
    else
      "updated_at"
    end
  end

  def create_workfile(workspace)
    workfile = nil
    workfile_params = params[:workfile]
    Workfile.transaction do
      if workfile_params[:type] == 'alpine'
        workfile = AlpineWorkfile.new(workfile_params)
        workfile.owner = current_user
        workfile.workspace = workspace
        workfile.save!
      elsif workfile_params[:svg_data]
        workfile = ChorusWorkfile.create_from_svg(workfile_params, workspace, current_user)
      else
        workfile = ChorusWorkfile.create_from_file_upload(workfile_params, workspace, current_user)
      end

      Events::WorkfileCreated.by(current_user).add(
        :workfile => workfile,
        :workspace => workspace,
        :commit_message => workfile_params[:description]
      )

      workspace.has_added_workfile = true
      workspace.save!
    end

    workfile
  end
end
