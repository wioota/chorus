class DatasetStreamer < SqlStreamer
  attr_accessor :dataset

  def initialize(dataset, user, options = {})
    row_limit = options[:row_limit]
    sql = dataset.all_rows_sql(row_limit)
    super(dataset.schema, sql, user, row_limit: row_limit)
  end

  def empty_results_error
    "The requested dataset contains no rows"
  end
end