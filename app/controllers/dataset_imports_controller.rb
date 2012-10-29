class DatasetImportsController < ApplicationController
  def index
    workspace = Workspace.find(params[:workspace_id])
    table = Dataset.find(params[:dataset_id])
    imports = Import.where('source_dataset_id = ? OR (to_table = ? AND workspace_id = ?)',
                           table.id, table.name, workspace.id).order('created_at DESC')
    imports = imports.limit(params[:limit]) if params[:limit]
    present imports
  end

  def create
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace

    src_table = Dataset.find(params[:dataset_id])

    import = src_table.imports.new(params)

    import.workspace    = workspace
    import.user         = current_user

    if import.save
      import.create_import_event
      QC.enqueue("Import.run", import.id)
      render :json => {}, :status => :created
    else
      raise ApiValidationError.new(import.errors)
    end
  end
end
