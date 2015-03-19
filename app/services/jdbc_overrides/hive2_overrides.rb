require Rails.root.join('vendor/hadoop/hdfs-query-service-0.0.11.jar')

module JdbcOverrides
  module Hive2
    class QueryError < StandardError; end

    module ConnectionOverrides
      HiveConnection = com.emc.greenplum.hadoop.HiveConnection

      HDFS_VERSIONS = {
          'Cloudera CDH5' => '4.0.0',
          'Hortonworks HDP 2.1' => '4.0.0',
          'MapR4' => '0.20.2mr'
      }

      def prepare_and_execute_statement(query, options={}, cancelable_query = nil)
        with_connection do |connection|
          statement = connection.createStatement
          statement.set_fetch_size(1000)
          statement.set_max_rows(options[:limit]) if options[:limit]
          result = statement.executeQuery(query)
          JdbcSqlResult.new({:result_set => result})
          #statement = build_and_configure_statement(connection, options, query)
          #cancelable_query.store_statement(statement) if cancelable_query
          #
          #begin
          #  set_timeout(options[:timeout], statement) if options[:timeout]
          #  # If you try to set auto commit at all, hive fails.
          #  #jdbc_conn.set_auto_commit(false) if options[:limit]
          #
          #  if options[:describe_only]
          #    statement.execute_with_flags(org.postgresql.core::QueryExecutor::QUERY_DESCRIBE_ONLY)
          #  else
          #    statement.execute
          #  end
          #
          #  result = query_result(options, statement)
          #  # jdbc_conn.commit if options[:limit]
          #  result
          #rescue Exception => e
          #  raise PostgresLikeConnection::QueryError, "The query could not be completed. Error: #{e.message}"
          #end
        end
      end

      def connect!
        hive_connection_object = HiveConnection.new()
        @connection ||=  @data_source.hive_kerberos ?
            hive_connection_object.getHiveKerberosConnection(@data_source.host, Thread.current[:user].username, @data_source.hive_kerberos_principal, @data_source.hive_kerberos_keytab_location, HDFS_VERSIONS[@data_source.hive_hadoop_version]) :
            hive_connection_object.getHiveConnection(@data_source.host, @account.db_username, @account.db_password,HDFS_VERSIONS[@data_source.hive_hadoop_version])

      end

      def schemas
        with_connection do |connection|
          ss = []
          schemas = connection.getMetaData.getSchemas
          while schemas.next
            ss << schemas.getString(1)
          end
          ss
        end
      end

      def datasets(options={})
        with_connection do |connection|
          res = []
          tables = connection.getMetaData.getTables('',schema_name,'%',nil)
          while tables.next

            res << {:name => tables.getString(3), :type => table_type?(tables.getString(4))}
          end
          res
        end
      end

      def metadata_for_dataset(dataset_name)
        with_connection do |connection|
          column_count = 0
          columns = connection.getMetaData.getColumns('',schema_name,dataset_name,'%')
          while columns.next
            column_count += 1
          end
          {:column_count => column_count}
        end
      end

      def metadata_get_tables(types, opts)
        with_connection do |connection|
          res = {}
          tables = connection.getMetaData.getTables('',opts[:schema],opts[:table_name],types.to_java(:string))
          if tables.next
            res = {:table_name => tables.getString(3)}
          end
          yield res
        end
      end

      def column_info(dataset_name, setup_sql)
        with_connection do |connection|
          cols = []
          columns = connection.getMetaData.getColumns('',schema_name,dataset_name,'%')
          while columns.next

            cols << {:attname => columns.getString(4), :format_type => schema_column_type(columns.getString(6))}
          end
          cols
        end
      end

      def disconnect
        # Hive2 doesn't implement close() on the connection.
        #@connection.disconnect if @connection
        @connection = nil
      end

      def schema_column_type(db_type)
        case db_type
          when /\A(character( varying)?|n?(var)?char|n?text|string|clob)/io
            :string
          when /\A(int(eger)?|(big|small|tiny)int)/io
            :integer
          when /\Adate\z/io
            :date
          when /\A((small)?datetime|timestamp( with(out)? time zone)?)(\(\d+\))?\z/io
            :datetime
          when /\Atime( with(out)? time zone)?\z/io
            :time
          when /\A(bool(ean)?)\z/io
            :boolean
          when /\A(real|float|double( precision)?|double\(\d+,\d+\)( unsigned)?)\z/io
            :float
          when /\A(?:(?:(?:num(?:ber|eric)?|decimal)(?:\(\d+,\s*(\d+|false|true)\))?))\z/io
            $1 && ['0', 'false'].include?($1) ? :integer : :decimal
          when /bytea|blob|image|(var)?binary/io
            :blob
          when /\Aenum/io
            :enum
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

    def self.VisualizationOverrides
      return Visualization::Hive2Sql
    end
  end
end
