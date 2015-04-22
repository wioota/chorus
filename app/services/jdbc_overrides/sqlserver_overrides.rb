module JdbcOverrides
  module SqlServer
    module ConnectionOverrides
    end

    module CancelableQueryOverrides
    end

    module DatasetOverrides
    end

    def self.VisualizationOverrides
      return Visualization::SqlServerSql
    end
  end
end