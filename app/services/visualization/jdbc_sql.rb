module Visualization
  module JdbcSql
    def frequency_row_sql(o)
      dataset, bins, category, filters = fetch_opts(o, :dataset, :bins, :category, :filters)

      query = <<-SQL
        SELECT TOP #{bins} #{category} AS bucket, count(1) AS counted
          FROM #{dataset.scoped_name}
            GROUP BY #{category}
            ORDER BY counted DESC
      SQL
      query << " WHERE #{filters.join(' AND ')}" if filters.present?
      query
    end
  end
end
