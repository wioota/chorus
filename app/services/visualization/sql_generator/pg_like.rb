module Visualization
  module SqlGenerator
    class PgLike < Base
      def frequency_row_sql(o)
        dataset, bins, category, filters = fetch_opts(o, :dataset, :bins, :category, :filters)
        relation = relation(dataset)

        query = relation.
            group(relation[category]).
            project(relation[category].as('bucket'), Arel.sql('count(1)').as('count')).
            order(Arel.sql('count').desc).
            take(bins)
        query = query.where(Arel.sql(filters.join(' AND '))) if filters.present?

        query.to_sql
      end

      def boxplot_row_sql(o)
        dataset, values, category, buckets, filters = fetch_opts(o, :dataset, :values, :category, :buckets, :filters)

        filters = filters.present? ? "#{filters.join(' AND ')} AND" : ''

        ntiles_for_each_datapoint = <<-SQL
          SELECT "#{category}", "#{values}", ntile(4) OVER (t) AS ntile
            FROM #{dataset.scoped_name}
              WHERE #{filters} "#{category}" IS NOT NULL AND "#{values}" IS NOT NULL WINDOW t
              AS (PARTITION BY "#{category}" ORDER BY "#{values}")
        SQL

        ntiles_for_each_bucket = <<-SQL
          SELECT "#{category}", ntile, MIN("#{values}"), MAX("#{values}"), COUNT(*) cnt
            FROM (#{ntiles_for_each_datapoint}) AS ntilesForEachDataPoint
              GROUP BY "#{category}", ntile ORDER BY "#{category}", ntile
        SQL

        # this was removed previously, but is a key performance optimization and must remain in place.
        # The query needs to limit the number of buckets, there could be a large number of rows
        # the 'limit' clause is the important part, not the 'total' field
        ntiles_for_each_bin_with_total = <<-SQL
          SELECT "#{category}", ntile, min, max, cnt, SUM(cnt) OVER(w) AS total
            FROM (#{ntiles_for_each_bucket}) AS ntilesForEachBin
              WINDOW w AS (PARTITION BY "#{category}")
              ORDER BY total desc, "#{category}", ntile LIMIT #{(buckets * 4).to_s}
        SQL

        ntiles_for_each_bin_with_total
      end

      def heatmap_min_max_sql(o)
        dataset, x_axis, y_axis = fetch_opts(o, :dataset, :x_axis, :y_axis)
        relation = relation(dataset)

        query = relation.project(
            relation[x_axis].minimum.as('xmin'), relation[x_axis].maximum.as('xmax'),
            relation[y_axis].minimum.as('ymin'), relation[y_axis].maximum.as('ymax')
        )

        query.to_sql
      end

      def heatmap_row_sql(o)
        x_axis, x_bins, min_x, max_x = fetch_opts(o, :x_axis, :x_bins, :min_x, :max_x)
        y_axis, y_bins, min_y, max_y = fetch_opts(o, :y_axis, :y_bins, :min_y, :max_y)
        dataset, filters = fetch_opts(o, :dataset, :filters)

        query = <<-SQL
          SELECT *, count(*) AS value FROM (
            SELECT width_bucket(
              CAST("#{x_axis}" AS numeric),
              CAST(#{min_x} AS numeric),
              CAST(#{max_x} AS numeric),
              #{x_bins}
            ) AS x,
            width_bucket( CAST("#{y_axis}" AS numeric),
              CAST(#{min_y} AS numeric),
              CAST(#{max_y} AS numeric),
              #{y_bins}
            ) AS y FROM ( SELECT * FROM #{dataset.scoped_name}
        SQL

        query +=  ' WHERE ' + filters.join(' AND ') if filters.present?

        query += <<-SQL
          ) AS subquery
            WHERE "#{x_axis}" IS NOT NULL
            AND "#{y_axis}" IS NOT NULL) AS foo
            GROUP BY x, y
        SQL
        
        query
      end

      def histogram_min_max_sql(o)
        relation = relation(o[:dataset])
        category = o[:category]

        query = relation.
            project(relation[category].minimum.as('min'), relation[category].maximum.as('max'))

        query.to_sql
      end

      def histogram_row_sql(o)
        dataset, min, max, bins, filters, category = fetch_opts(o, :dataset, :min, :max, :bins, :filters, :category)
        relation = relation(dataset)
        scoped_category = %(#{dataset.scoped_name}."#{category}")

        width_bucket = "width_bucket(CAST(#{scoped_category} as numeric), CAST(#{min} as numeric), CAST(#{max} as numeric), #{bins})"

        query = relation.
            group(width_bucket).
            project(Arel.sql(width_bucket).as('bucket'), Arel.sql("COUNT(#{width_bucket})").as('frequency')).
            where(relation[category].not_eq(nil))

        query = query.where(Arel.sql(filters.join(' AND '))) if filters.present?

        query.to_sql
      end

      def timeseries_row_sql(o)
        time, time_interval, aggregation = fetch_opts(o, :time, :time_interval, :aggregation)
        value, filters, pattern = fetch_opts(o, :value, :filters, :pattern)
        relation = relation(o[:dataset])

        date_trunc = %(date_trunc('#{time_interval}' ,"#{time}"))

        query = relation.
            group(Arel.sql(date_trunc)).
            project(Arel.sql(%(#{aggregation}("#{value}"), to_char(#{date_trunc}, '#{pattern}') ))).
            order(Arel.sql(date_trunc).asc)
        query = query.where(Arel.sql(filters.join(' AND '))) if filters.present?

        query.to_sql
      end
    end
  end
end
