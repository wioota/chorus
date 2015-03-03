module JdbcOverrides
  module Mariadb
    module ConnectionOverrides
      def schemas
        with_connection do |connection|
          ss = []
          connection.process_metadata(:getCatalogs) do |h|
            ss << h[:table_cat] unless @schema_blacklist.include?(h[:table_cat])
          end
          ss
        end
      end

      def metadata_for_dataset(dataset_name)
        column_count = with_connection do |connection|
          columns_enum(connection, dataset_name).count
        end
        {:column_count => column_count}
      end

      def column_info(dataset_name, setup_sql)
        with_connection do |connection|
          columns_enum(connection, dataset_name).map do |col|
            { :attname => col[:column_name], :format_type => col[:type_name] }
          end
        end
      end

      private

      def columns_enum(connection, dataset_name)
        connection.to_enum(:process_metadata, :getColumns, schema_name, nil, dataset_name, nil)
      end

      def metadata_get_tables(types, opts, &block)
        with_connection do |connection|
          connection.process_metadata(:getTables, opts[:schema], nil, opts[:table_name], types.to_java(:string), &block)
        end
      end
    end

    module CancelableQueryOverrides
    end

    module DatasetOverrides
    end

    def self.VisualizationOverrides
      return Visualization::MariadbSql
    end
  end
end