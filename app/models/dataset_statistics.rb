class DatasetStatistics
  attr_reader :description, :definition, :row_count, :column_count, :table_type,
              :last_analyzed, :disk_size, :partition_count

  def parse_analyzed_date(date)
    Time.parse(date).utc if date
  end

  def self.for_dataset(dataset, account)
    result = dataset.query_results(account, :metadata_for_dataset)

    stats = new(result)

    if stats.partition_count && stats.partition_count > 0
      partition_result = dataset.query_results(account, :partition_data_for_dataset)

      total_disk_size = stats.disk_size + partition_result['disk_size'].to_i
      stats.instance_variable_set(:@disk_size, total_disk_size)
    end

    stats
  end

  def initialize(row)
    return unless row

    @definition   = row['definition']
    @description  = row['description']
    @column_count = row['column_count'] && row['column_count'].to_i
    @row_count = row['row_count'] && row['row_count'].to_i
    @table_type = row['table_type']
    @last_analyzed = parse_analyzed_date(row['last_analyzed'])
    @disk_size = row['disk_size'] && row['disk_size'].to_i
    @partition_count = row['partition_count'] && row['partition_count'].to_i
  end

  def entity_type_name
    'dataset_statistics'
  end
end
