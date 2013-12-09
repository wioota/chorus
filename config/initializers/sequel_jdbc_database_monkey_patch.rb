require 'sequel/adapters/jdbc'

module Sequel
  module JDBC
    class Database < Sequel::Database
      def schemas
        ss = []
        m = output_identifier_meth
        metadata(:getSchemas){ |h| ss << m.call(h[:table_schem]) }
        ss
      end
    end
  end
end