# https://github.com/rails/rails/issues/11595
module ActiveRecord
  module Calculations
    def pluck(column_name)
      if column_name.is_a?(Symbol) && column_names.include?(column_name.to_s)
        column_name = "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(column_name)}"
      end
      klass.connection.select_values(select(column_name).to_sql)
    end
  end
end
