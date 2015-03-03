module JdbcOverrides
  module Hive2
    class QueryError < StandardError; end

    module ConnectionOverrides
      def prepare_and_execute_statement(query, options={}, cancelable_query = nil)
        with_jdbc_connection(options) do |jdbc_conn|
          statement = build_and_configure_statement(jdbc_conn, options, query)
          cancelable_query.store_statement(statement) if cancelable_query

          begin
            set_timeout(options[:timeout], statement) if options[:timeout]
            # If you try to set auto commit at all, hive fails.
            #jdbc_conn.set_auto_commit(false) if options[:limit]

            if options[:describe_only]
              statement.execute_with_flags(org.postgresql.core::QueryExecutor::QUERY_DESCRIBE_ONLY)
            else
              statement.execute
            end

            result = query_result(options, statement)
            # jdbc_conn.commit if options[:limit]
            result
          rescue Exception => e
            raise PostgresLikeConnection::QueryError, "The query could not be completed. Error: #{e.message}"
          end
        end
      end
    end

    module CancelableQueryOverrides
      def sql_execution_timeout
        # Hive fails upon setting an execution timeout
        0
      end

      def format_sql_and_check_id(sql)
        # Hive fails if you have a /* */ style comment
        "#{sql}"
      end


    end

    module DatasetOverrides
      def all_rows_sql(limit = nil)
        query = "SELECT * FROM #{schema.name}.#{name}"
        query << " LIMIT #{limit}" if limit
        query
      end

      def scoped_name
        %(#{schema_name}.#{name})
      end
    end

    module VisualizationOverrides
      include Visualization::Hive2Sql
    end
  end
end
