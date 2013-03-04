class OracleTableCopier < TableCopier
  def self.requires_chorus_authorization?
    true
  end

  def run
    destination_connection.connect!
    destination_connection.create_external_table(:location_url => stream_url, :temporary => true, :web => true,
      :table_name => source_dataset.name, :columns => table_definition)
    destination_connection.copy_table_data(%Q{"#{destination_schema.name}"."#{destination_table_name}"}, source_dataset.name, '')
  ensure
    destination_connection.disconnect
  end

  private

  def distribution_key_columns
    primary_key_columns
  end

  def convert_column_type(oracle_type)
    OracleDbTypeConversions.convert_column_type oracle_type
  end
end