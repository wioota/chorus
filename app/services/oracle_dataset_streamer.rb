if ChorusConfig.instance.oracle_configured?
  begin
    require_relative '../../lib/libraries/ojdbc6.jar'
  rescue LoadError
    Rails.logger.warn "Error loading Oracle driver"
  end
elsif ChorusConfig.instance.oracle_driver_expected_but_missing?
  Rails.logger.warn "Oracle driver ojdbc6.jar not found"
end

class OracleDatasetStreamer
  def enum
    Enumerator.new do |result|
      conn = make_connection

      begin
        conn.synchronize do |jdbc_conn|
          jdbc_conn.set_auto_commit(false)

          stmnt = jdbc_conn.create_statement
          stmnt.set_fetch_size(10)

          result_set = stmnt.execute_query('select * from demo.demo_states')
          column_number = result_set.meta_data.column_count

          while (result_set.next) do
            record = []

            column_number.times do |i|
              record << result_set.get_string(i+1)
            end

            result << record.join(",")+"\n"
          end

          result_set.close
        end
      ensure
        conn.disconnect
      end
    end
  end

  private

  def make_connection
    Sequel.connect(db_url, :test => true)
  end

  def db_url
    'jdbc:oracle:thin:system/oracle@//chorus-oracle:1521/orcl'
  end
end