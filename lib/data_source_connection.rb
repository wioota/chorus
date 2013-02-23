require 'sequel'

class DataSourceConnection
  class Error < StandardError
    def initialize(exception = nil)
      if exception
        super(exception.message)
        @exception = exception
      end
    end

    def to_s
      sanitize_message super
    end

    def message
      sanitize_message super
    end

    private

    def sanitize_message(message)
      message
    end
  end

  class QueryError < StandardError; end

  def fetch(sql, parameters = {})
    with_connection { @connection.fetch(sql, parameters).all }
  end

  def fetch_value(sql)
    with_connection { @connection.fetch(sql).single_value }
  end

  def execute(sql)
    with_connection { @connection.execute(sql) }
    true
  end

  def stream_dataset(dataset, limit = nil, &block)
    stream_sql(dataset.all_rows_sql, limit, &block)
  end

  def stream_sql(sql, limit = nil)
    with_connection do
      @connection.synchronize do |jdbc_conn|
        jdbc_conn.set_auto_commit(false)

        stmnt = jdbc_conn.create_statement
        stmnt.set_fetch_size(1000)
        stmnt.set_max_rows(limit) if limit

        result_set = stmnt.execute_query(sql)
        column_number = result_set.meta_data.column_count

        while(result_set.next) do
          record = {}

          column_number.times do |i|
            record[result_set.meta_data.column_name(i+1).to_sym] = result_set.get_string(i+1)
          end

          yield record
        end

        result_set.close
        jdbc_conn.close
      end
    end

    true
  end

  def prepare_and_execute_statement(query, options = {})
    with_connection options do
      @connection.synchronize do |jdbc_conn|
        if options[:timeout]
          set_timeout(options[:timeout], jdbc_conn)
        end

        statement = jdbc_conn.prepare_statement(query)
        if options[:limit]
          jdbc_conn.set_auto_commit(false)
          statement.set_fetch_size(options[:limit])
          statement.set_max_rows(options[:limit])
        end

        if options[:describe_only]
          statement.execute_with_flags(org.postgresql.core::QueryExecutor::QUERY_DESCRIBE_ONLY)
        else
          statement.execute
        end

        if options[:limit]
          jdbc_conn.commit
        end

        warnings = []
        if options[:warnings]
          warning = statement.get_warnings
          while (warning)
            warnings << warning.to_s
            warning = warning.next_warning
          end
        end

        result_set = statement.get_result_set
        if support_multiple_result_sets?
          while (statement.more_results(statement.class::KEEP_CURRENT_RESULT) || statement.update_count != -1)
            result_set.close if result_set
            result_set = statement.get_result_set
          end
        end

        create_sql_result(warnings, result_set)
      end
    end
  rescue Exception => e
    e.backtrace.each { |line| pa line }
    raise QueryError, "The query could not be completed. Error: #{e.message}"
  end

  def support_multiple_result_sets?
    false
  end
end