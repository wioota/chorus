class OracleDatasetColumn < DatasetColumn
  def supported?
    !!OracleDbTypeConversions.convert_column_type(data_type.upcase)
  end

  def gpdb_data_type
    OracleDbTypeConversions.convert_column_type(data_type.upcase)
  end
end
