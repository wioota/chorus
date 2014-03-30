module Visualization
  UnknownType = Class.new(StandardError)

  def self.build(dataset, attributes)
    case attributes[:type]
      when 'frequency' then Visualization::Frequency
      when 'histogram' then Visualization::Histogram
      when 'heatmap' then Visualization::Heatmap
      when 'timeseries' then Visualization::Timeseries
      when 'boxplot' then Visualization::Boxplot
      else raise UnknownType, "Unknown visualization: #{attributes[:type]}"
    end.new(dataset, attributes)
  end

  class Base
    include CurrentUser

    def row_sql
      @dataset.query_setup_sql + build_row_sql
    end

    def min_max_sql
      @dataset.query_setup_sql + build_min_max_sql
    end

    def relation
      @relation ||= Arel::Table.new(@dataset.scoped_name)
    end
  end
end
