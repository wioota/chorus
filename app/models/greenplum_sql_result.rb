class GreenplumSqlResult < SqlResult
  def dataset_column_class
    GpdbDatasetColumn
  end
end