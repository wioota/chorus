module Visualization
  module PgLikeSql
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
