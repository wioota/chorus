class OracleSqlResult < SqlResult
  def column_string_value(meta_data, result_set, index)
    supported = OracleDbTypeConversions::GREENPLUM_TYPE_MAP.keys
    if supported.include? meta_data.column_type_name(index)
      super
    else
      meta_data.get_column_name(index)
    end
  end

  def dataset_column_class
    OracleDatasetColumn
  end
end