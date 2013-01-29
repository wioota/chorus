require_relative 'gpdb_column_statistics'

class GpdbColumn
  attr_accessor :data_type, :description, :ordinal_position, :statistics, :name, :statistics

  def self.columns_for(account, dataset)
    self.columns_for_table(account, dataset)
  end

  def self.columns_for_table(account, table)
    columns_with_stats = table.connect_with(account).column_info(table.name, table.query_setup_sql)

    columns_with_stats.map.with_index do |raw_row_data, i|
      column = GpdbColumn.new({
        :name => raw_row_data[:attname],
        :data_type => raw_row_data[:format_type],
        :description => raw_row_data[:description],
        :ordinal_position => i + 1
      })
      params = []
      params << raw_row_data[:null_frac]
      params << raw_row_data[:n_distinct]
      params << raw_row_data[:most_common_vals]
      params << raw_row_data[:most_common_freqs]
      params << raw_row_data[:histogram_bounds]
      params << raw_row_data[:reltuples]
      params << column.number_or_time?
      column.statistics = GpdbColumnStatistics.new(*params)
      column
    end
  end

  def initialize(attributes={})
    @name = attributes[:name]
    @data_type = attributes[:data_type]
    @description = attributes[:description]
    @ordinal_position = attributes[:ordinal_position]
  end

  def simplified_type
    @simplified_type ||= ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(name, nil, data_type, nil).type
  end

  def number_or_time?
    [:decimal, :integer, :float, :date, :time, :datetime].include? simplified_type
  end

  def entity_type_name
    'gpdb_column'
  end
end
