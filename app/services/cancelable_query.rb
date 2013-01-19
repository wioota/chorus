class CancelableQuery
  def initialize(connection, check_id)
    @connection = connection
    @check_id = check_id
  end

  def execute(sql, options = {})
    @connection.prepare_and_execute_statement("/*#{@check_id}*/#{sql}", options.merge(:warnings => true))
  end

  def cancel
    @connection.fetch("select pg_cancel_backend(procpid) from pg_stat_activity where current_query LIKE '/*#{@check_id}*/%'")
  end
end
