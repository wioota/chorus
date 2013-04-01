class OracleTableCopier < TableCopier
  def self.requires_chorus_authorization?
    true
  end

  def run
    destination_connection.connect!.synchronize do |jdbc_conn|
      copy_manager(jdbc_conn).copy_in(copy_sql, java_stream)
    end
  ensure
    destination_connection.disconnect
  end

  private

  def copy_manager(jdbc_conn)
    org.postgresql.copy.CopyManager.new(jdbc_conn)
  end

  def copy_sql
    "COPY #{destination_table_fullname}(#{column_names}) FROM STDIN WITH DELIMITER ',' CSV"
  end

  def java_stream
    java.io.InputStreamReader.new(org.jruby.util.IOInputStream.new(EnumeratorIO.new(streamer.enum)))
  end

  def streamer
    @streamer ||= SqlStreamer.new(
        source_dataset.all_rows_sql(sample_count),
        source_connection,
        {:show_headers => false}
    )
  end

  def column_names
    account = source_dataset.data_source.account_for_user!(user)
    columns = DatasetColumn.columns_for(account, source_dataset)
    columns.map { |column| "\"#{column.name}\"" }.join(", ")
  end

  def distribution_key_columns
    primary_key_columns
  end

  def convert_column_type(oracle_type)
    OracleDataTypes.greenplum_type_for oracle_type
  end
end