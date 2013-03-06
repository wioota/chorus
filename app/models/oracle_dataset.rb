class OracleDataset < Dataset
  def database_name
   ''
  end

  def instance_account_ids
    schema.instance_account_ids
  end

  def found_in_workspace_id
    []
  end

  def column_type
    "OracleDatasetColumn"
  end

  def all_rows_sql(limit = nil)
    query = "SELECT * FROM \"#{schema.name}\".\"#{name}\""
    query << " WHERE rownum <= #{limit}" if limit
    query
  end
end
