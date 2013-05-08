class WorkspaceDatasetsController < ApplicationController
  include DataSourceAuth

  def index
    authorize! :show, workspace
    options = {
        :entity_subtype => params[:entity_subtype],
        :database_id => params[:database_id],
        :limit => params[:page].to_i * params[:per_page].to_i
    }.reject { |_, v| v.nil? }

    if params[:name_pattern]
      options.merge!(:name_filter => params[:name_pattern])
    end

    params.merge!(:total_entries => workspace.dataset_count(current_user, options))
    datasets = workspace.datasets(current_user, options).includes(Dataset.eager_load_associations).list_order

    present paginate(datasets), :presenter_options => { :workspace => workspace }
  end

  def create
    authorize! :can_edit_sub_objects, workspace
    datasets = Dataset.where(:id => params[:dataset_ids])

    status = associate_many_datasets(datasets) ? :created : :unprocessable_entity

    render :json => {}, :status => status
  end

  def show
    authorize! :show, workspace

    dataset = params[:name] ? Dataset.find_by_name(params[:name]) : Dataset.find(params[:id])
    dataset.in_workspace?(workspace) or raise ActiveRecord::RecordNotFound

    authorize_data_source_access(dataset)

    if dataset.schema.verify_in_source(current_user) && dataset.verify_in_source(current_user)
      present dataset, {:presenter_options => {:workspace => workspace}}
    else
      render_dataset_with_error(dataset)
    end

  rescue GreenplumConnection::DatabaseError => e
    render_dataset_with_error(dataset, e.error_type)
  end

  def render_dataset_with_error(dataset, error_type = :MISSING_DB_OBJECT)
    json = {
        :response => Presenter.present(dataset, view_context, {:workspace => workspace}),
        :errors => {:record => error_type}
    }
    render json: json, status: :unprocessable_entity
  end

  def destroy
    authorize! :can_edit_sub_objects, workspace
    dataset = AssociatedDataset.find_by_dataset_id_and_workspace_id(params[:id], params[:workspace_id])
    dataset.destroy
    render :json => {}
  end

  private

  def workspace
    @workspace ||= Workspace.workspaces_for(current_user).find(params[:workspace_id])
  end

  def associate_many_datasets(datasets)
    Workspace.transaction do
      datasets.each do |dataset|
        raise ActiveRecord::Rollback unless dataset.associable?

        unless workspace.has_dataset?(dataset)
          workspace.source_datasets << dataset
          create_event_for_dataset(dataset, workspace)
        end
      end
    end
  end

  def create_event_for_dataset(dataset, workspace)
    Events::SourceTableCreated.by(current_user).add(
        :dataset => dataset,
        :workspace => workspace
    )
  end
end

