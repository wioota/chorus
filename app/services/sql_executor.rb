module SqlExecutor
  class << self
    def preview_dataset(dataset, connection, check_id, user)
      execute_sql(dataset.preview_sql, connection, dataset.schema, check_id, user, :limit => ChorusConfig.instance['default_preview_row_limit'])
    end

    def execute_sql(sql, connection, schema, check_id, user, options = {})
      cancelable_query = CancelableQuery.new(connection, check_id, user)

      options.merge!({ :timeout => sql_execution_timeout }) if sql_execution_timeout > 0
      cancelable_query.execute(sql, options)
    end

    def cancel_query(gpdb_connection_provider, account, check_id, user)
      CancelableQuery.new(gpdb_connection_provider.connect_with(account), check_id, user).cancel
    end

    def stream(sql, connection, check_id, user, options={})
      stream_options = {}
      stream_options[:limit] = options[:row_limit] if options[:row_limit].to_i > 0
      stream_options[:quiet_null] = !!options[:quiet_null]

      cancelable_query = CancelableQuery.new(connection, check_id, user)
      cancelable_query.stream(sql, stream_options)
    end

    def sql_execution_timeout
      (60 * (ChorusConfig.instance["execution_timeout_in_minutes"] || 0))
    end
  end
end

