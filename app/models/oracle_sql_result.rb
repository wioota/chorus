class OracleSqlResult < SqlResult
  private

  def column_string_value(index)
    column = columns[index]
    if column.supported?
      super
    else
      column.data_type.downcase
    end
  end

  def dataset_column_class
    OracleDatasetColumn
  end
end
