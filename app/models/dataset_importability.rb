class DatasetImportability
  def initialize(dataset)
    @dataset = dataset
  end

  def importable?
    @dataset.kind_of?(GpdbDataset) || invalid_columns.empty?
  end

  def invalid_columns
    invalid_columns = []

    @dataset.column_data.each do |column|
      unless supported_column_types.include? column.data_type
        invalid_columns << {
          column_name: column.name,
          column_type: column.data_type
        }
      end
    end

    invalid_columns
  end

  def supported_column_types
    OracleDataTypes::GREENPLUM_TYPE_MAP.keys
  end
end