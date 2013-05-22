class WorkfileCopyController < ApplicationController

  def create
    workfile = Workfile.find(params[:workfile_id])
    authorize! :show, workfile

    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace
    copied_workfile = workfile.copy(current_user, workspace)
    copied_workfile.resolve_name_conflicts = true

    copied_workfile.build_new_version(current_user, workfile.latest_workfile_version.contents, "") if copied_workfile.respond_to?(:build_new_version)
    copied_workfile.save!

    present copied_workfile.reload, :status => :created
  end
end
