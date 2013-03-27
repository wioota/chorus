class CancelableQuery
  def self.format_sql_and_check_id(sql, check_id)
    "/*#{check_id}*/#{sql}"
  end

  def initialize(connection, check_id)
    @connection = connection
    @check_id = check_id
  end

  def execute(sql, options = {})
    @connection.prepare_and_execute_statement(CancelableQuery.format_sql_and_check_id(sql, @check_id), options.merge(:warnings => true))
  end

  def cancel
    cancel = @connection.fetch("select pg_cancel_backend(procpid) from pg_stat_activity where current_query LIKE '/*#{@check_id}*/%'")
    !!cancel[0] && cancel[0][:pg_cancel_backend]
  end

  def busy?
    @connection.fetch("select procpid from pg_stat_activity where current_query LIKE '/*#{@check_id}*/%'").any?
  end
end
