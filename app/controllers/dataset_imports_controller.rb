class DatasetImportsController < ApplicationController
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

  # TODO #41244423: allow users to terminate their own imports
  before_filter :require_admin, :only => :update
  def update
    ids = [*params[:id]]

    ids.each do |id|
      import = Import.find(id)
      #authorize! :update, import

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

  def create
    import_params = params[:dataset_import]
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace

    src_table = Dataset.find(import_params[:dataset_id])
    src_table.check_duplicate_column(current_user) if src_table.is_a?(ChorusView)

    import = src_table.imports.new(import_params)

    import.workspace = workspace
    import.user = current_user

    import.save!
    import.create_import_event
    QC.enqueue_if_not_queued("ImportExecutor.run", import.id)
    render :json => {}, :status => :created
  end
end
