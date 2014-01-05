require 'sequel/adapters/jdbc'

module Sequel
  module JDBC
    class Database < Sequel::Database
      def schemas
        ss = []
        metadata(:getSchemas){ |h| ss << h[:table_schem] }
        ss
      end

      def tables(opts={})
        get_tables_s(%w(TABLE), opts)
      end

      def views(opts={})
        get_tables_s(%w(VIEW), opts)
      end

      def tables_and_views(opts={})
        get_tables_s(%w(TABLE VIEW), opts)
      end

      def version
        synchronize do |c|
          c.getMetaData.send(:getDatabaseProductVersion)
        end
      end

      private

      def get_tables_s(types, opts)
        ts = []
        metadata(:getTables, nil, opts[:schema], opts[:table_name], types.to_java(:string)){ |h| ts << { :name => h[:table_name], :type => table_type?(h[:table_type])} }
        ts
      end

      def table_type?(type)
        case type
          when 'TABLE' then 't'
          when 'VIEW' then 'v'
          else nil
        end
      end
    end
  end
end