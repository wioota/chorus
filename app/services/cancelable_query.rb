class CancelableQuery
  @@running_statements = {}

  def self.format_sql_and_check_id(sql, check_id)
    "/*#{check_id}*/#{sql}"
  end

  def initialize(connection, check_id)
    @connection = connection
    @check_id = check_id
  end

  def execute(sql, options = {})
    @connection.prepare_and_execute_statement(CancelableQuery.format_sql_and_check_id(sql, @check_id), options.merge(:warnings => true)) do |statement|
      @@running_statements[@check_id] = statement
    end
  ensure
    @@running_statements.delete(@check_id)
  end

  def cancel
    @@running_statements[@check_id].cancel if @@running_statements.has_key?(@check_id)
  end

  def busy?
    @connection.fetch("select procpid from pg_stat_activity where current_query LIKE '/*#{@check_id}*/%'").any?
  end
end
