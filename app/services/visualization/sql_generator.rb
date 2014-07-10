module Visualization
  class SqlGenerator
    NotImplemented = Class.new(ApiValidationError)

    def frequency_row_sql(opts)
      not_implemented
    end

    def boxplot_row_sql(opts)
      not_implemented
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
