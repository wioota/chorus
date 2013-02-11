class DatasetStatistics
  attr_reader :description, :definition, :row_count, :column_count, :table_type,
              :last_analyzed, :disk_size, :partition_count

  def self.build_for(dataset, account)
    if dataset.kind_of?(ChorusView)
      result = dataset.schema.connect_with(account).prepare_and_execute_statement(dataset.query, :describe_only => true)
      return self.new('column_count' => result.columns.count)
    end

    connection = dataset.schema.connect_with(account)
    metadata = connection.metadata_for_dataset(dataset.name)

    return nil unless metadata
    stats = self.new(metadata)

    if stats.partition_count && stats.partition_count > 0
      partition_result = connection.partition_data_for_dataset(dataset.name)

      total_disk_size = stats.disk_size + partition_result['disk_size'].to_i
      stats.instance_variable_set(:@disk_size, total_disk_size)
    end

    stats
  end

  def initialize(row)
    row = row.with_indifferent_access

    @definition   = row['definition']
    @description  = row['description']
    @column_count = row['column_count'] && row['column_count'].to_i
    @row_count = row['row_count'] && row['row_count'].to_i
    @table_type = row['table_type']
    @last_analyzed = row['last_analyzed'].try(:utc)
    @disk_size = row['disk_size'] && row['disk_size'].to_i
    @partition_count = row['partition_count'] && row['partition_count'].to_i
  end

  def entity_type_name
    'dataset_statistics'
  end
end
