class OracleDatasetColumn < DatasetColumn
  def supported?
    !!OracleDbTypeConversions.convert_column_type(data_type.upcase)
  end
end
