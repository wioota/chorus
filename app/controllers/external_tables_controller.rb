class ExternalTablesController < GpdbController
  wrap_parameters :hdfs_external_table, :exclude => []

  def create
    workspace = Workspace.find(params[:workspace_id])
    hdfs_entry = HdfsEntry.find(params[:hdfs_external_table][:hdfs_entry_id])

    unless workspace.sandbox
      present_validation_error(:EMPTY_SANDBOX)
      return
    end

    account = authorized_gpdb_account(workspace.sandbox)
    url = Gpdb::ConnectionBuilder.url(workspace.sandbox.database, account)

    e = ExternalTable.build(
      :column_names => params[:hdfs_external_table][:column_names],
      :column_types => params[:hdfs_external_table][:types],
      :database => url,
      :delimiter => params[:hdfs_external_table][:delimiter],
      :file_expression => params[:hdfs_external_table][:file_expression],
      :has_header => params[:hdfs_external_table][:has_header],
      :location_url => hdfs_entry.url,
      :name => params[:hdfs_external_table][:table_name],
      :schema_name => workspace.sandbox.name
    )
    if e.save
      Dataset.refresh(account, workspace.sandbox)
      dataset = workspace.sandbox.reload.datasets.find_by_name!(params[:hdfs_external_table][:table_name])
      create_event(dataset, workspace, hdfs_entry)
      render :json => {}, :status => :ok
    else
      raise ApiValidationError.new(e.errors)
    end
  end

  private

  def present_validation_error(error_code)
    present_errors({:fields => {:external_table => {error_code => {}}}},
                   :status => :unprocessable_entity)
  end

  def create_event(dataset, workspace, hdfs_file)
    Events::WorkspaceAddHdfsAsExtTable.by(current_user).add(
        :workspace => workspace,
        :dataset => dataset,
        :hdfs_file => hdfs_file
    )
  end
end
