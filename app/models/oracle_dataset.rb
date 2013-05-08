class OracleDataset < Dataset
  def database_name
   ''
  end

  def data_source_account_ids
    schema.data_source_account_ids
  end

  def found_in_workspace_id
    []
  end

  def column_type
    "OracleDatasetColumn"
  end

  def all_rows_sql(limit = nil)
    select_clause = column_data.map do |column_data|
      if column_data.supported?
        "\"#{column_data.name}\""
      else
        "'#{column_data.data_type.downcase}' AS \"#{column_data.name}\""
      end
    end.join(', ')
    query = "SELECT #{select_clause} FROM \"#{schema.name}\".\"#{name}\""
    query << " WHERE rownum <= #{limit}" if limit
    query
  end

  def can_import_into(destination)
    destination_columns = destination.column_data
    source_columns = column_data

    consistent_size = source_columns.size == destination_columns.size

    consistent_size && source_columns.all? do |source_column|
      destination_columns.find { |destination_column| source_column.match?(destination_column) }
    end
  end

  def associable?
    false
  end

  def in_workspace?(workspace)
    false
  end
end
