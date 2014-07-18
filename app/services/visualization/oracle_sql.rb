module Visualization
  module OracleSql
    def frequency_row_sql(o)
      dataset, bins, category, filters = fetch_opts(o, :dataset, :bins, :category, :filters)

      query = <<-SQL
      SELECT * FROM (
        SELECT "#{category}" AS "bucket", count(1) AS "counted"
          FROM #{dataset.scoped_name}
      SQL

      query << " WHERE #{filters.join(' AND ')}" if filters.present?

      query << <<-SQL
          GROUP BY "#{category}"
          ORDER BY "counted" DESC
        ) WHERE ROWNUM <= #{bins}
      SQL

      query
    end

    def boxplot_row_sql(o)
      raise NotImplemented
    end

    def timeseries_row_sql(o)
      raise NotImplemented
    end
  end
end
