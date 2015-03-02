module JdbcOverrides
  module Teradata
    module ConnectionOverrides
    end

    module CancelableQueryOverrides
    end

    module DatasetOverrides
    end

    module VisualizationOverrides
      include Visualization::TeradataSql
    end
  end
end