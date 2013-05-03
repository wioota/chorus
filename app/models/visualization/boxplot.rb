module Visualization
  class Boxplot < Base
    attr_accessor :rows, :buckets, :category, :values, :filters, :type
    attr_writer :dataset, :schema

    def initialize(dataset=nil, attributes={})
      @buckets = attributes[:bins].to_i
      @category = attributes[:x_axis]
      @values = attributes[:y_axis]
      @filters = attributes[:filters]
      @type = attributes[:type]
      @dataset = dataset
      @schema = dataset.try :schema
    end

    def fetch!(account, check_id)
      result = CancelableQuery.new(@schema.connect_with(account), check_id, current_user).execute(row_sql)
      ntiles_for_each_bucket = result.rows.map { |row| {:bucket => row[0], :ntile => row[1].to_i, :min => row[2].to_f, :max => row[3].to_f, :count => row[4].to_i} }
      @rows = BoxplotSummary.summarize(ntiles_for_each_bucket, @buckets)
    end

    private

    def build_row_sql
      filters = @filters.present? ? "#{@filters.join(" AND ")} AND" : ""

      ntiles_for_each_datapoint = <<-SQL
        SELECT "#{@category}", "#{@values}", ntile(4) OVER (t) AS ntile
        FROM #{@dataset.scoped_name}
        WHERE #{filters} "#{@category}" IS NOT NULL AND "#{@values}" IS NOT NULL WINDOW t
        AS (PARTITION BY "#{@category}" ORDER BY "#{@values}")
      SQL

      ntiles_for_each_bucket = <<-SQL
        SELECT "#{@category}", ntile, MIN("#{@values}"), MAX("#{@values}"), COUNT(*) cnt
        FROM (#{ntiles_for_each_datapoint}) AS ntilesForEachDataPoint
        GROUP BY "#{@category}", ntile ORDER BY "#{@category}", ntile
      SQL

      return ntiles_for_each_bucket
    end
  end
end
