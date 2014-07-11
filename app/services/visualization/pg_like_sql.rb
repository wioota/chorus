module Visualization
  module PgLikeSql
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
