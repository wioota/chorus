class JdbcDataset < RelationalDataset
  delegate :data_source, :to => :schema

  def database_name
    ''
  end

  def column_type
    'JdbcDatasetColumn'
  end

  def data_source_account_ids
    schema.data_source_account_ids
  end

  def found_in_workspace_id
    bound_workspace_ids
  end

  def all_rows_sql(limit = nil)
    Arel::Table.new(%("#{schema_name}"."#{name}")).project('*').to_sql
  end
end