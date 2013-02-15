class DatasetStreamer < SqlStreamer
  attr_accessor :dataset
  def initialize(dataset, user, row_limit = nil)
    super(dataset.schema, dataset.all_rows_sql(row_limit), user, row_limit)
  end

  def empty_results_error
    "The requested dataset contains no rows"
  end
end