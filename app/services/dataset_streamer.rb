require 'csv'
class DatasetStreamer
  attr_accessor :dataset, :user, :format, :row_limit
  def initialize(dataset, user, row_limit = nil)
    self.dataset = dataset
    self.user = user
    self.row_limit = row_limit
  end

  def format(hash, first_row_flag)
    results = ''
    results << hash.keys.to_csv if first_row_flag
    results << hash.values.to_csv
    results
  end

  def enum
    first_row_flag = true

    conn = dataset.schema.connect_as(user)
    Enumerator.new do |y|
      begin
        conn.stream_dataset(dataset, row_limit) do |row|
          y << format(row, first_row_flag)
          first_row_flag = false
        end
        if (first_row_flag)
          y << "The requested dataset contains no rows"
        end
      rescue Exception => e
        y << e.message
      end
    end
  end
end