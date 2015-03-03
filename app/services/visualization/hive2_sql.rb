module Visualization
  module Hive2Sql
    def self.extend_object(obj)
      super
      obj.limit_type = :top
    end

    def frequency_row_sql(o)
      dataset, bins, category, filters = fetch_opts(o, :dataset, :bins, :category, :filters)

      limits = limit_clause(bins)

      query = <<-SQL
        SELECT #{limits[:top]} #{category} AS bucket, count(1) AS counted
          FROM #{dataset.schema_name}.#{dataset.name}
      SQL
      query << " WHERE #{filters.join(' AND ')}" if filters.present?
      query << " GROUP BY #{category}"
      query << ' ORDER BY counted DESC'
      query << " #{limits[:limit]}" if limits[:limit]
      query
    end

    def heatmap_min_max_sql(o)
      raise NotImplemented
    end

    def heatmap_row_sql(o)
      raise NotImplemented
    end

    def histogram_min_max_sql(o)
      raise NotImplemented
    end

    def histogram_row_sql(o)
      raise NotImplemented
    end

    def timeseries_row_sql(o)
      raise NotImplemented
    end
  end
end
