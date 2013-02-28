class OracleDatasetColumn < DatasetColumn
  def is_supported?
    OracleDbTypeConversions::GREENPLUM_TYPE_MAP.keys.include? data_type.upcase
  end
end
