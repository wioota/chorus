require 'csv'
class SqlStreamer
  attr_accessor :schema, :sql, :user, :row_limit
  def initialize(schema, sql, user, row_limit = nil)
    self.schema = schema
    self.sql = sql
    self.user = user
    self.row_limit = row_limit
  end

  def format(hash, row_number)
    results = ''
    results << hash.keys.to_csv if row_number == 1
    results << hash.values.to_csv
    results
  end

  def empty_results_error
    "The query returned no rows"
  end

  def row_limit
    @row_limit.to_i if @row_limit.to_i > 0
  end

  def enum
    row_number = 0
    account = schema.gpdb_instance.account_for_user!(user)

    Enumerator.new do |y|
      begin
        schema.with_gpdb_connection(account) do |conn|
          ActiveRecord::Base.each_row_by_sql(sql, :connection => conn, :until => :finished) do |row|
            row_number += 1
            y << format(row, row_number)
            :finished if row_limit && row_number >= row_limit
          end

          if (row_number == 0)
            y << empty_results_error
          end
        end
      rescue Exception => e
        y << e.message
      end

      ActiveRecord::Base.connection.close
    end
  end
end