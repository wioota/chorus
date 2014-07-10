module Visualization
  class SqlGenerator
    attr_accessor :limit_type

    NotImplemented = Class.new(ApiValidationError)

    def initialize(params={})
      @limit_type = params.fetch(:limit, :limit)
    end

    def frequency_row_sql(opts)
      not_implemented
    end

    def boxplot_row_sql(o)
      dataset, values, category, buckets, filters = fetch_opts(o, :dataset, :values, :category, :buckets, :filters)

      filters = filters.present? ? "#{filters.join(' AND ')} AND" : ''

      ntiles_for_each_datapoint = <<-SQL
      SELECT "#{category}", "#{values}", ntile(4) OVER (
        PARTITION BY "#{category}"
        ORDER BY "#{values}"
      ) AS ntile
        FROM #{dataset.scoped_name}
          WHERE #{filters} "#{category}" IS NOT NULL AND "#{values}" IS NOT NULL
      SQL

      ntiles_for_each_bucket = <<-SQL
      SELECT "#{category}", ntile, MIN("#{values}") "min", MAX("#{values}") "max", COUNT(*) cnt
        FROM (#{ntiles_for_each_datapoint}) AS ntilesForEachDataPoint
          GROUP BY "#{category}", ntile
      SQL

      limits = limit_clause((buckets * 4).to_s)

      # this was removed previously, but is a key performance optimization and must remain in place.
      # The query needs to limit the number of buckets, there could be a large number of rows
      ntiles_for_each_bin_with_total = <<-SQL
      SELECT #{limits[:top]} "#{category}", ntile, "min", "max", cnt, SUM(cnt) OVER(
        PARTITION BY "#{category}"
      ) AS total
        FROM (#{ntiles_for_each_bucket}) AS ntilesForEachBin
        ORDER BY total desc, "#{category}", ntile #{limits[:limit]};
      SQL

      ntiles_for_each_bin_with_total
    end

    def heatmap_min_max_sql(opts)
      not_implemented
    end

    def heatmap_row_sql(opts)
      not_implemented
    end

    def histogram_min_max_sql(opts)
      not_implemented
    end

    def histogram_row_sql(opts)
      not_implemented
    end

    def timeseries_row_sql(opts)
      not_implemented
    end

    private

    def limit_clause(limit)
      {
          :top => limit_type == :top ? "TOP #{limit}" : '',
          :limit => limit_type == :limit ? "LIMIT #{limit}" : ''
      }
    end

    def relation(dataset)
      @relation ||= Arel::Table.new(dataset.scoped_name)
    end

    def fetch_opts(opts, *keys)
      keys.map { |key| opts.fetch key }
    end

    def not_implemented
      raise NotImplemented.new :visualization, :not_implemented
    end
  end
end
