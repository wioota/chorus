class PreviewsController < GpdbController
  wrap_parameters :task, :exclude => [:id, :dataset_id]

  def create
    dataset = Dataset.find(params[:dataset_id])
    instance_account = authorized_gpdb_account(dataset)

    result = SqlExecutor.preview_dataset(dataset, instance_account, params[:task][:check_id])
    present(result, :status => :created)
  end

  def destroy
    dataset = Dataset.find(params[:dataset_id])
    instance_account = authorized_gpdb_account(dataset)

    SqlExecutor.cancel_query(dataset, instance_account, params[:id])
    head :ok
  end

  def preview_sql
    task = params[:task]
    schema = GpdbSchema.find(task[:schema_id])
    instance_account = authorized_gpdb_account(schema)

    sql_without_semicolon = task[:query].gsub(';', '')
    sql = "SELECT * FROM (#{sql_without_semicolon}) AS chorus_view;"
    result = SqlExecutor.execute_sql(schema, instance_account, task[:check_id], sql, :limit => limit_rows)
    present(result, :status => :ok)
  end

  private

  # TODO: DRY this out of this controller and the workfile executions controller [#39410527]
  def limit_rows
    (Chorus::Application.config.chorus['default_preview_row_limit'] || 500).to_i
  end
end
