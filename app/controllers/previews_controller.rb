class PreviewsController < ApplicationController
  include DataSourceAuth

  wrap_parameters :task, :exclude => [:id, :dataset_id]

  def create
    dataset = Dataset.find(params[:dataset_id])
    instance_account = authorized_account(dataset)

    result = SqlExecutor.preview_dataset(dataset, instance_account, params[:task][:check_id])
    present(result, :status => :created)
  end

  def destroy
    dataset = Dataset.find(params[:dataset_id])
    instance_account = authorized_account(dataset)

    SqlExecutor.cancel_query(dataset, instance_account, params[:id])
    head :ok
  end

  def preview_sql
    task = params[:task]
    schema = GpdbSchema.find(task[:schema_id])
    instance_account = authorized_account(schema)

    sql_without_semicolon = task[:query].gsub(';', '')
    sql = "SELECT * FROM (#{sql_without_semicolon}) AS chorus_view;"
    result = SqlExecutor.execute_sql(schema, instance_account, task[:check_id], sql, :limit => ChorusConfig.instance['default_preview_row_limit'])
    present(result, :status => :ok)
  end
end
