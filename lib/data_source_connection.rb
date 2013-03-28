require 'sequel'

class DataSourceConnection
  LIKE_ESCAPE_CHARACTER = "@"

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

  class DriverNotConfigured < StandardError;
    attr_accessor :data_source
    def initialize(data_source)
      self.data_source = data_source
    end
  end

  def self.escape_like_string(input_string)
    input_string.gsub(/[\_\%#{LIKE_ESCAPE_CHARACTER}]/) { |c| LIKE_ESCAPE_CHARACTER + c }
  end

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

  def stream_sql(sql, options = {})
    with_connection do
      @connection.synchronize do |jdbc_conn|
        jdbc_conn.set_auto_commit(false)

        stmnt = jdbc_conn.create_statement
        stmnt.set_fetch_size(1000)
        stmnt.set_max_rows(options[:limit]) if options[:limit]

        result_set = stmnt.execute_query(sql)

        meta_data = result_set.meta_data
        column_names = (1..meta_data.column_count).map {|i| meta_data.column_name(i).to_sym}

        nil_value = options[:quiet_null] ? "" : "null"
        parser = SqlValueParser.new(result_set, :nil_value => nil_value)

        while result_set.next
          record = {}

          column_names.each.with_index do |name, i|
            record[name] = parser.string_value(i)
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
        statement = jdbc_conn.prepare_statement(query)

        yield statement if block_given?

        if options[:timeout]
          set_timeout(options[:timeout], statement)
        end

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

        result = create_sql_result(warnings, result_set)

        if options[:limit]
          jdbc_conn.commit
        end

        result
      end
    end
  rescue Exception => e
    raise QueryError, "The query could not be completed. Error: #{e.message}"
  end

  def support_multiple_result_sets?
    false
  end
end