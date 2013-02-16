require 'csv'
class SqlStreamer
  attr_accessor :schema, :sql, :user, :row_limit
  def initialize(schema, sql, user, row_limit = nil)
    self.schema = schema
    self.sql = sql
    self.user = user
    self.row_limit = row_limit
  end
  def format(hash, first_row_flag)
    results = ''
    results << hash.keys.to_csv if first_row_flag
    results << hash.values.to_csv
    results
  end

  def empty_results_error
    "The query returned no rows"
  end

  def row_limit
    @row_limit.to_i if @row_limit.to_i > 0
  end

  def enum(show_headers = true)
    connection = schema.connect_as(user)

    Enumerator.new do |y|
      begin
        connection.stream_sql(sql, row_limit) do |row|
          y << format(row, show_headers)
          show_headers = false
        end
        if show_headers
          y << empty_results_error
        end
      rescue Exception => e
        y << e.message
      end

      ActiveRecord::Base.connection.close
    end
  end
end