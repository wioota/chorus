class MultiPgTableCopier < TableCopier
  include_package 'org.postgresql.copy'

  def run
    source_data_stream = source_connection.connect!.synchronize do |source_jdbc|
      PGCopyInputStream.new source_jdbc, copy_out_sql
    end

    destination_connection.with_jdbc_connection do |destination_jdbc|
      destination_jdbc.copy_api.copy_in(copy_in_sql, source_data_stream)
    end
  ensure
    source_connection.disconnect
  end

  def self.cancel(import)
    source_connection = import.source.connect_as(import.user)
    source_connection.kill(import.handle)
  end

  private

  def copy_out_sql
    %(/*#{pipe_name}*/ COPY #{source_dataset.scoped_name} TO STDOUT WITH DELIMITER ',' CSV)
  end
end
