module SqlExecutor
  class << self
    def preview_dataset(dataset, account, check_id)
      execute_sql(dataset.schema, account, check_id, dataset.preview_sql, :limit => limit_rows)
    end

    def execute_sql(schema, account, check_id, sql, options = {})
      conn = schema.connect_with(account)
      cancelable_query = CancelableQuery.new(conn, check_id)

      options.merge!({ :timeout => sql_execution_timeout }) if sql_execution_timeout > 0
      result = cancelable_query.execute(sql, options)
      result.schema = schema

      result
    end

    def cancel_query(gpdb_connection_provider, account, check_id)
      CancelableQuery.new(gpdb_connection_provider.connect_with(account), check_id).cancel
    end

    def sql_execution_timeout
      (60 * 1000 * (ChorusConfig.instance["execution_timeout_in_minutes"] || 0))
    end

    def limit_rows
      (ChorusConfig.instance['default_preview_row_limit'] || 500).to_i
    end
  end
end

