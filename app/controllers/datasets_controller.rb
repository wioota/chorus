class DatasetsController < ApplicationController
  include DataSourceAuth

  def index
    schema = Schema.find(params[:schema_id])
    account = authorized_account(schema)

    options = {}
    options[:name_filter] = params[:filter] if params[:filter]
    options[:tables_only] = params[:tables_only] if params[:tables_only]

    refresh_options = options.merge(:limit => params[:page].to_i * params[:per_page].to_i)
    datasets = schema.refresh_datasets(account, refresh_options).includes(Dataset.eager_load_associations)
    params.merge!(:total_entries => schema.dataset_count(account, options))

    present paginate(datasets)
  end

  def show
    authorize_data_source_access(Dataset.find(params[:id]))
    table = Dataset.find_and_verify_in_source(params[:id].to_i, current_user)
    present table
  end
end