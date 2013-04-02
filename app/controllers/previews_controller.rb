class PreviewsController < ApplicationController
  include DataSourceAuth

  wrap_parameters :task, :exclude => [:id, :dataset_id]

  def create
    dataset = Dataset.find(params[:dataset_id])
    authorize_data_source_access(dataset)

    result = SqlExecutor.preview_dataset(dataset, dataset.connect_as(current_user), params[:task][:check_id])
    present(result, :status => :created)
  end

  def destroy
    dataset = Dataset.find(params[:dataset_id])
    authorize_data_source_access(dataset)

    SqlExecutor.cancel_query(dataset, dataset.connect_as(current_user), params[:id])
    head :ok
  end

  def preview_sql
    task = params[:task]
    schema = GpdbSchema.find(task[:schema_id])
    authorize_data_source_access(schema)

    sql_without_semicolon = task[:query].gsub(';', '')
    sql = "SELECT * FROM (#{sql_without_semicolon}) AS chorus_view;"
    result = SqlExecutor.execute_sql(sql, schema.connect_as(current_user), schema, task[:check_id], :limit => ChorusConfig.instance['default_preview_row_limit'])
    present(result, :status => :ok)
  end
end
