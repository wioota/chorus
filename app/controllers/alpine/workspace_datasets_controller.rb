module Alpine
  class WorkspaceDatasetsController < AlpineController
    def index
      datasets = workspace.datasets(current_user, :dataset_ids => params[:dataset_ids]).includes(Dataset.eager_load_succinct_associations).list_order
      present datasets, :presenter_options => { :workspace => workspace, :succinct => true }
    end

    private

    def workspace
      @workspace ||= Workspace.workspaces_for(current_user).find(params[:workspace_id])
    end
  end
end