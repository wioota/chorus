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
