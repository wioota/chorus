module Visualization
  module SqlServerSql
    # sql server does not support width_bucket and needs a special
    # implementation for heatmap and histogram
    def heatmap_min_max_sql(o)
      raise NotImplemented.new
    end

    def heatmap_row_sql(o)
      raise NotImplemented.new
    end

    def histogram_min_max_sql(o)
      raise NotImplemented.new
    end

    def histogram_row_sql(o)
      raise NotImplemented.new
    end

    # sql server does not support trunc or date_trunc
    # and needs special implementation
    def timeseries_row_sql(o)
      raise NotImplemented.new
    end
  end
end
