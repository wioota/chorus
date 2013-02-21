class OracleDataset < Dataset
  def database_name
   ''
  end

  def instance_account_ids
    #TODO: 41841357 this should be only account that still worked the last time we polled the data source
    schema.data_source.accounts.map(&:id)
  end

  def found_in_workspace_id
    []
  end

  def column_type
    "OracleDatasetColumn"
  end
end
