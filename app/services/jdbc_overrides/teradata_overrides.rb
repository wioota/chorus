module JdbcOverrides
  module Teradata
    module ConnectionOverrides
    end

    module CancelableQueryOverrides
    end

    module DatasetOverrides
    end

    def self.VisualizationOverrides
      return Visualization::TeradataSql
    end
  end
end