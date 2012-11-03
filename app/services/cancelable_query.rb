class CancelableQuery < MultipleResultsetQuery
  def initialize(connection, check_id)
    super(connection)
    @check_id = check_id
  end

  def execute(sql, options = {})
    super("/*#{@check_id}*/#{sql}", options)
  end

  def cancel
    @connection.exec_query("select pg_terminate_backend(pid) from pg_stat_activity where query LIKE '/*#{@check_id}*/%'")
  rescue ActiveRecord::StatementInvalid
    # for pre-9.2 postgres
    @connection.exec_query("select pg_cancel_backend(procpid) from pg_stat_activity where current_query LIKE '/*#{@check_id}*/%'")
  end
end
