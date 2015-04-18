module Visualization
  module Hive2Sql
    def self.extend_object(obj)
      super
      obj.limit_type = :limit
    end

    def frequency_row_sql(o)
      dataset, bins, category, filters = fetch_opts(o, :dataset, :bins, :category, :filters)

      limits = limit_clause(bins)

      # Naively remove double quotes from filter strings, and hive dies if you give it schema_name.relation_name.(otherstuff); only relation_name.otherstuff allowed.
      filters.map! { |x| x.tr("\"", '').gsub(/#{dataset.schema_name}\.#{dataset.name}\./, "#{dataset.name}.") } if filters.present?

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
      #
      #dataset = fetch_opts(o, :dataset).first
      #relation = relation(o[:dataset])
      #category = o[:category]
      #
      #query = relation.
      #    project(relation[category].minimum.as('"min"'), relation[category].maximum.as('"max"'))
      #
      #q = query.to_sql.tr("\"", '').gsub(/#{dataset.schema_name}\.#{dataset.name}\./, "#{dataset.name}.")
      #
      #q
    end

    def histogram_row_sql(o)
      raise NotImplemented
      # "width_bucket" doesn't exist in hiveql, but there are other ways to get the same data.
      # deferring to later, but leaving below for reference. See "histogram_numeric" in hive
      #
      #dataset, min, max, bins, filters, category = fetch_opts(o, :dataset, :min, :max, :bins, :filters, :category)
      #relation = relation(dataset)
      #scoped_category = %(#{dataset.scoped_name}."#{category}")
      #
      #width_bucket = "width_bucket(CAST(#{scoped_category} as #{numeric_cast}), CAST(#{min} as #{numeric_cast}), CAST(#{max} as #{numeric_cast}), #{bins})"
      #
      #query = relation.
      #    group(width_bucket).
      #    project(Arel.sql(width_bucket).as('bucket'), Arel.sql("COUNT(#{width_bucket})").as('frequency')).
      #    where(relation[category].not_eq(nil))
      #
      #query = query.where(Arel.sql(filters.join(' AND '))) if filters.present?
      #
      #q = query.to_sql.tr("\"", '').gsub(/#{dataset.schema_name}\.#{dataset.name}\./, "#{dataset.name}.")
      #q = q.gsub(/as numeric/, "as decimal")
      #
      #q
    end

    def timeseries_row_sql(o)
      raise NotImplemented
    end

    def boxplot_row_sql(o)
      raise NotImplemented
    end
  end
end
