module Visualization
  module TeradataSql
    def boxplot_row_sql(o)
      dataset, values, category, buckets, filters = fetch_opts(o, :dataset, :values, :category, :buckets, :filters)

      filters = filters.present? ? "#{filters.join(' AND ')} AND" : ''

      # td does not support ntile, so approximate with
      # (RANK() OVER(...) - 1) * n / (COUNT(*) OVER (...))
      ntiles_for_each_datapoint = <<-SQL
      SELECT "#{category}", "#{values}", (RANK() OVER (
        PARTITION BY "#{category}"
        ORDER BY "#{values}"
      ) - 1) * 4 / (COUNT(*) OVER (
        PARTITION BY "#{category}"
        ORDER BY "#{values}"
      )) AS ntile
        FROM #{dataset.scoped_name}
          WHERE #{filters} "#{category}" IS NOT NULL AND "#{values}" IS NOT NULL
      SQL

      ntiles_for_each_bucket = <<-SQL
      SELECT "#{category}", ntile, MIN("#{values}") "min", MAX("#{values}") "max", COUNT(*) cnt
        FROM (#{ntiles_for_each_datapoint}) AS ntilesForEachDataPoint
          GROUP BY "#{category}", ntile
      SQL

      limits = limit_clause((buckets * 4).to_s)

      # td does not allow nested ordered analytic functions, so we cannot order by
      # total using this syntax as before...
      ntiles_for_each_bin_with_total = <<-SQL
      SELECT #{limits[:top]} "#{category}", ntile, "min", "max", cnt
        FROM (#{ntiles_for_each_bucket}) AS ntilesForEachBin
        ORDER BY "#{category}", ntile #{limits[:limit]};
      SQL

      ntiles_for_each_bin_with_total
    end

    def histogram_row_sql(o)
      dataset, min, max, bins, filters, category = fetch_opts(o, :dataset, :min, :max, :bins, :filters, :category)
      relation = relation(dataset)
      scoped_category = %(#{dataset.scoped_name}."#{category}")

      width_bucket = "width_bucket(CAST(#{scoped_category} as numeric(32)), CAST(#{min} as numeric(32)), CAST(#{max} as numeric(32)), #{bins})"

      query = relation.
          group(width_bucket).
          project(Arel.sql(width_bucket).as('bucket'), Arel.sql("COUNT(#{width_bucket})").as('frequency')).
          where(relation[category].not_eq(nil))

      query = query.where(Arel.sql(filters.join(' AND '))) if filters.present?

      query.to_sql
    end
  end
end
