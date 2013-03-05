require 'csv'

class SqlStreamer
  attr_accessor :schema, :sql, :user, :row_limit, :target_is_greenplum

  def initialize(schema, sql, user, options = {})
    self.schema = schema
    self.sql = sql
    self.user = user
    self.row_limit = options[:row_limit]
    self.target_is_greenplum = options[:target_is_greenplum]
  end

  def format_row(row)
    result = row.to_csv
    result.gsub!('|', '\\|') if self.target_is_greenplum
    result
  end

  def format(hash, first_row_flag)
    results = ''
    results << format_row(hash.keys) if first_row_flag
    results << format_row(hash.values)
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