class OracleSqlResult < SqlResult
  def column_string_value(meta_data, result_set, index)
    supported = OracleDbTypeConversions::GREENPLUM_TYPE_MAP.keys
    data_type = meta_data.column_type_name(index)
    if supported.include? data_type
      super
    else
      data_type.downcase
    end
  end

  def dataset_column_class
    OracleDatasetColumn
  end
end