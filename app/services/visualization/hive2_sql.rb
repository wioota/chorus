module Visualization
  module Hive2Sql
    def self.extend_object(obj)
      super
      obj.limit_type = :top
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
