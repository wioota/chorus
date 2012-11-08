module SqlExecutor
  class << self
    def preview_dataset(dataset, account, check_id)
      execute_sql(dataset.schema, account, check_id, dataset.preview_sql, :limit => 100)
    end

    def execute_sql(schema, account, check_id, sql, options = {})
        schema.with_gpdb_connection(account) do |conn|
          cancelable_query = CancelableQuery.new(conn, check_id)

          if (options[:timeout] && options[:timeout] > 0)
            cancelable_query.execute("SET statement_timeout TO #{options[:timeout]}", options)
          end

          result = cancelable_query.execute(sql, options)
          result.schema = schema
          result
        end
    end

    def cancel_query(gpdb_connection_provider, account, check_id)
      gpdb_connection_provider.with_gpdb_connection(account) do |conn|
        cancelable_query = CancelableQuery.new(conn, check_id)
        cancelable_query.cancel
      end
    end
  end
end

