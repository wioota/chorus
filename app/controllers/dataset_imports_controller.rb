class DatasetImportsController < ApplicationController
  before_filter :require_admin, :only => :update
  wrap_parameters :dataset_import, :exclude => [:id]

  def index
    workspace = Workspace.find(params[:workspace_id])
    authorize! :show, workspace

    table = Dataset.find(params[:dataset_id])
    if (table.is_a?(ChorusView))
      imports = Import.where('source_dataset_id = ?',
                             table.id).order('created_at DESC')
    else
      imports = Import.where('source_dataset_id = ? OR (to_table = ? AND workspace_id = ?)',
                             table.id, table.name, workspace.id).order('created_at DESC')
    end
    present paginate imports
  end

  def update
    ids = [*params[:id]]

    ids.each do |id|
      import = Import.find(id)
      authorize! :update, import

      unless import.finished_at
        dataset_import_params = params[:dataset_import]
        ImportExecutor.cancel(import, dataset_import_params[:success].to_s == "true", dataset_import_params[:message])
      end
    end

    respond_to do |format|
      format.json { render :json => {}, :status => 200 }
      format.html { redirect_to ":#{ChorusConfig.instance.server_port}/import_console/imports" }
    end
  end
end
