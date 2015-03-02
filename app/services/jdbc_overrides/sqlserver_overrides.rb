module JdbcOverrides
  module SqlServer
    module ConnectionOverrides
    end

    module CancelableQueryOverrides
    end

    module DatasetOverrides
    end

    module VisualizationOverrides
      include Visualization::SqlServerSql
    end
  end
end