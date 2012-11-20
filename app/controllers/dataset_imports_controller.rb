class DatasetImportsController < ApplicationController
  wrap_parameters :dataset_import, :exclude => [:id]
  def index
    workspace = Workspace.find(params[:workspace_id])
    authorize! :show, workspace

    table = Dataset.find(params[:dataset_id])
    imports = Import.where('source_dataset_id = ? OR (to_table = ? AND workspace_id = ?)',
                           table.id, table.name, workspace.id).order('created_at DESC')
    present paginate imports
  end

  def create
    import_params = params[:dataset_import]
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace

    src_table = Dataset.find(params[:dataset_id])
    import = src_table.imports.new(import_params)

    import.workspace    = workspace
    import.user         = current_user

    if import.save
      import.create_import_event
      QC.enqueue_if_not_queued("ImportExecutor.run", import.id)
      render :json => {}, :status => :created
    else
      raise ApiValidationError.new(import.errors)
    end
  end
end
