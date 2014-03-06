class OracleTableCopier < TableCopier
  def run
    destination_connection.connect!.synchronize do |jdbc_conn|
      copy_manager(jdbc_conn).copy_in(copy_sql, java_stream)
    end
  ensure
    destination_connection.disconnect
  end

  def self.cancel(import)
    connection = import.source_dataset.data_source.connect_as(import.user)
    cancelable_query = CancelableQuery.new(connection, import.handle, import.user)
    cancelable_query.cancel
    kill_session(cancelable_query, connection)
  end

  def self.kill_session(cancelable_query, connection)
    #Get the session id of the sql job running on oracle for the import and kill/disconnect that session
    #Not tested due to difficulty with multiple threads.  Be careful if changing this.
    sid = connection.fetch(sid_sql(cancelable_query)).first
    sid && connection.execute(cancel_sql(sid[:sid]))
  end

  private

  def self.sid_sql(cancelable_query)
    <<-SQL
    SELECT
    ''''||sid||', '||s.serial#||'''' sid
    FROM V$SESSION s,
        V$SQLAREA sa
    WHERE sa.sql_text like '%#{cancelable_query.check_id}%'
    AND  s.type != 'BACKGROUND'
    AND  s.program = 'JDBC Thin Client'
    AND  sid != sys_context('userenv', 'sid')
    ORDER BY sid
    SQL
  end

  def self.cancel_sql(sid)
    <<-SQL
      ALTER SYSTEM DISCONNECT SESSION #{sid} IMMEDIATE
    SQL
  end

  def copy_manager(jdbc_conn)
    org.postgresql.copy.CopyManager.new(jdbc_conn)
  end

  def copy_sql
    "COPY #{destination_table_fullname}(#{column_names}) FROM STDIN WITH DELIMITER ',' CSV"
  end

  def java_stream
    java.io.InputStreamReader.new(org.jruby.util.IOInputStream.new(EnumeratorIO.new(streamer_enum)))
  end

  def streamer_enum
    cancelable_query.stream(source_dataset.all_rows_sql(sample_count), {:show_headers => false})
  end

  def cancelable_query
    @cancelable_query ||= CancelableQuery.new(source_connection, pipe_name, user)
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
