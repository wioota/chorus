require 'csv'

class SqlStreamer
  def initialize(sql, connection, options = {})
    @sql = sql
    @connection = connection
    @target_is_greenplum = options[:target_is_greenplum]
    @show_headers = options[:show_headers] == false ? false : true

    @stream_options = {}
    @stream_options[:row_limit] = options[:row_limit] if options[:row_limit].to_i > 0
    @stream_options[:quiet_null] = !!options[:quiet_null]
  end

  def enum
    first_row = @show_headers
    no_results = true

    Enumerator.new do |y|
      begin
        @connection.stream_sql(@sql, @stream_options) do |row|
          no_results = false

          if first_row && @show_headers
            y << format_row(row.keys)
            first_row = false
          end

          y << format_row(row.values)
        end

        if no_results && @show_headers
          y << empty_results_error
        end
      rescue Exception => e
        y << e.message
      end

      ActiveRecord::Base.connection.close
    end
  end

  private

  def empty_results_error
    "The query returned no rows"
  end

  def format_for_greenplum(value)
    if value.is_a?(String)
      return '' if value == '\0'
      value.gsub(/(\\n|\\r)/, ' ')
    else
      value
    end
  end

  def format_row(row)
    if @target_is_greenplum
      row.map { |value| format_for_greenplum(value) }
    else
      row
    end.to_csv
  end
end