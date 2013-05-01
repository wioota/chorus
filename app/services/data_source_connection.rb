require 'sequel'

class DataSourceConnection
  LIKE_ESCAPE_CHARACTER = "@"

  class Error < StandardError
    attr_reader :error_type

    def initialize(exception_or_error_type = nil)
      message = nil
      case exception_or_error_type
        when Exception
          message = exception_or_error_type.message
          @exception = exception_or_error_type
        when Symbol
          @error_type = exception_or_error_type
      end
      super message
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

  class InvalidCredentials < StandardError
    attr_accessor :subject
    def initialize(data_source)
      self.subject = data_source
    end

    def error_type
      :INVALID_CREDENTIALS
    end
  end

  class DriverNotConfigured < StandardError
    attr_accessor :data_source
    def initialize(data_source)
      self.data_source = data_source
    end
  end

  def self.escape_like_string(input_string)
    input_string.gsub(/[\_\%#{LIKE_ESCAPE_CHARACTER}]/) { |c| LIKE_ESCAPE_CHARACTER + c }
  end

  def initialize(data_source, account, options)
    @data_source = data_source
    @account = account
    @options = options
  end

  def connect!
    verify_driver_configuration
    if @account.invalid_credentials?
      raise InvalidCredentials.new(@data_source)
    else
      @connection ||= Sequel.connect db_url, db_options.merge({:test => true})
    end
  rescue Sequel::DatabaseError => e
    exception = error_class.new(e)

    if exception.error_type == :INVALID_PASSWORD
      @account.invalid_credentials!
      raise InvalidCredentials.new(@data_source)
    else
      raise exception
    end
  end

  def fetch(sql, parameters={})
    with_connection { @connection.fetch(sql, parameters).all }
  end

  def fetch_value(sql)
    with_connection { @connection.fetch(sql).single_value }
  end

  def execute(sql)
    with_connection { @connection.execute(sql) }
    true
  end


  def stream_sql(query, options={}, cancelable_query = nil, &record_handler)
    with_jdbc_connection(options) do |jdbc_conn|
      statement = build_and_configure_statement(jdbc_conn, options, query)

      cancelable_query.store_statement(statement) if cancelable_query
      statement.execute

      stream_through_block(options, record_handler, statement)

      jdbc_conn.close
    end
    true
  end

  def prepare_and_execute_statement(query, options={}, cancelable_query = nil)
    with_jdbc_connection(options) do |jdbc_conn|
      statement = build_and_configure_statement(jdbc_conn, options, query)
      cancelable_query.store_statement(statement) if cancelable_query

      begin
        set_timeout(options[:timeout], statement) if options[:timeout]

        if options[:describe_only]
          statement.execute_with_flags(org.postgresql.core::QueryExecutor::QUERY_DESCRIBE_ONLY)
        else
          statement.execute
        end

        result = query_result(options, statement)
        jdbc_conn.commit if options[:limit]
        result
      rescue Exception => e
        raise QueryError, "The query could not be completed. Error: #{e.message}"
      end

    end
  end

  def verify_driver_configuration
  end

  private


  def error_class
    DataSourceConnection::Error
  end

  def db_options
    if @options[:logger]
      { :logger => @options[:logger], :sql_log_level => :debug }
    else
      {}
    end
  end

  def stream_through_block(options, record_handler, statement)
    result_set = last_result_set(statement)
    meta_data = result_set.meta_data
    column_names = (1..meta_data.column_count).map { |i| meta_data.column_name(i).to_sym }
    nil_value = options[:quiet_null] ? "" : "null"
    parser = SqlValueParser.new(result_set, :nil_value => nil_value)

    while result_set.next
      record = {}
      column_names.each.with_index { |column, i| record[column] = parser.string_value(i) }
      record_handler.call(record)
    end
  end

  def query_result(options, statement)
    create_sql_result(warnings(options, statement), last_result_set(statement))
  end

  def build_and_configure_statement(jdbc_conn, options, query)
    statement = jdbc_conn.prepare_statement(query)
    jdbc_conn.set_auto_commit(false) if options[:limit]
    statement.set_fetch_size(options[:limit]) if options[:limit]
    statement.set_max_rows(options[:limit]) if options[:limit]
    statement
  end

  def with_jdbc_connection(options={})
    with_connection options do
      @connection.synchronize { |jdbc| yield jdbc }
    end
  end

  def warnings(options, statement)
    warnings = []
    if options[:warnings]
      warning = statement.get_warnings
      while (warning)
        warnings << warning.to_s
        warning = warning.next_warning
      end
    end
    warnings
  end

  def last_result_set(statement)
    result_set = statement.get_result_set
    if support_multiple_result_sets?
      while (statement.more_results(statement.class::KEEP_CURRENT_RESULT) || statement.update_count != -1)
        result_set.close if result_set
        result_set = statement.get_result_set
      end
    end
    result_set
  end

  def support_multiple_result_sets?
    false
  end
end
