module Visualization
  module SqlGenerator
    class Base

      class NotImplemented < StandardError; end

      def frequency_row_sql(opts)
        raise NotImplemented
      end

      def boxplot_row_sql(opts)
        raise NotImplemented
      end

      def heatmap_min_max_sql(opts)
        raise NotImplemented
      end

      def heatmap_row_sql(opts)
        raise NotImplemented
      end

      def histogram_min_max_sql(opts)
        raise NotImplemented
      end

      def histogram_row_sql(opts)
        raise NotImplemented
      end

      def timeseries_row_sql(opts)
        raise NotImplemented
      end

      private

      def relation(dataset)
        @relation ||= Arel::Table.new(dataset.scoped_name)
      end

      def fetch_opts(opts, *keys)
        keys.map { |key| opts.fetch key }
      end
    end
  end
end
