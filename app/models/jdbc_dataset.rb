class JdbcDataset < RelationalDataset
  delegate :data_source, :to => :schema

  def database_name
    ''
  end

  def data_source_account_ids
    schema.data_source_account_ids
  end

  def found_in_workspace_id
    bound_workspace_ids
  end
end