require 'fileutils'
require 'timeout'

class GpPipe < DelegateClass(GpTableCopier)
  class ImportFailed < StandardError; end

  def run
    if chorus_view?
      src_conn << attributes[:from_table][:query]
    end

    source_count = get_count(src_conn, source_table_path)
    count = [source_count, (row_limit || source_count)].min

    create_new_table = false
    if !table_exists?
      dst_conn << "CREATE TABLE #{destination_table_fullname}(#{table_definition_with_keys}) #{distribution_key_clause}"
      create_new_table = true
    elsif truncate?
      dst_conn << "TRUNCATE TABLE #{destination_table_fullname}"
    end

    pipe_file = File.join(gpfdist_data_dir, pipe_name)
    if count > 0
      system "mkfifo #{pipe_file}"
      src_conn << "CREATE WRITABLE EXTERNAL TEMPORARY TABLE #{write_pipe_name} (#{table_definition})
                             LOCATION ('#{GpPipe.write_protocol}://#{GpPipe.gpfdist_url}:#{gpfdist_write_port}/#{pipe_name}') FORMAT 'TEXT'"
      dst_conn << "CREATE EXTERNAL TEMPORARY TABLE #{read_pipe_name} (#{table_definition})
                           LOCATION ('#{GpPipe.read_protocol}://#{GpPipe.gpfdist_url}:#{gpfdist_read_port}/#{pipe_name}') FORMAT 'TEXT'"

      semaphore = java.util.concurrent.Semaphore.new(0)

      reader_finished = false
      writer_finished = false
      t1 = Thread.new { begin
                          reader_loop(count)
                        ensure
                          reader_finished = true
                          semaphore.release
                        end }
      t2 = Thread.new { begin
                          src_conn << writer_sql
                        ensure
                          writer_finished = true
                          semaphore.release
                        end }

      semaphore.acquire
      semaphore.tryAcquire(5000, java.util.concurrent.TimeUnit::MILLISECONDS)

      #see if we need to recover from any errors.
      if !reader_finished
        system "echo '' >> #{pipe_file}"
      elsif !writer_finished
        system "cat #{pipe_file} > /dev/null"
        raise Exception, "Contents could not be read."
      end

      t1.join
      t2.join
    end
  rescue Exception => e
    if create_new_table
      dst_conn << "DROP TABLE IF EXISTS #{destination_table_fullname}"
    end
    raise ImportFailed, e.message
  ensure
    FileUtils.rm pipe_file if pipe_file && File.exists?(pipe_file)
  end

  def reader_loop(count)
    while destination_count < count
      dst_conn << "INSERT INTO #{destination_table_fullname} (SELECT * FROM #{read_pipe_name});"
    end
  end

  def writer_sql
    "INSERT INTO #{write_pipe_name} (SELECT * FROM #{source_table_path} #{limit_clause});"
  end

  def write_pipe_name
    "#{pipe_name}_w"
  end

  def read_pipe_name
    "#{pipe_name}_r"
  end

  def self.gpfdist_url
    Chorus::Application.config.chorus['gpfdist.url']
  end

  def self.protocol
    Chorus::Application.config.chorus['gpfdist.ssl.enabled'] ? 'gpfdists' : 'gpfdist'
  end

  def self.write_protocol
    self.protocol
  end

  def self.read_protocol
    self.protocol
  end

  def pipe_name
    @pipe_name ||= "pipe_#{Process.pid}_#{Time.now.to_i}"
  end

  def src_conn
    @raw_src_conn ||= create_source_connection
  end

  def with_src_connection
    conn = create_source_connection
    yield conn
  rescue Exception => e
    raise e.inspect
  end

  def dst_conn
    @raw_dst_conn ||= create_destination_connection
  end

  def with_dst_connection
    conn = create_destination_connection
    yield conn
  rescue Exception => e
    raise e.inspect
  end

  private

  def gpfdist_data_dir
    Chorus::Application.config.chorus['gpfdist.data_dir']
  end

  def gpfdist_write_port
    Chorus::Application.config.chorus['gpfdist.write_port']
  end

  def gpfdist_read_port
    Chorus::Application.config.chorus['gpfdist.read_port']
  end

  def create_source_connection
    connection = Sequel.connect(source_database_url, :logger => Rails.logger)
    connection << %Q{set search_path to "#{source_schema_name}";}
  end

  def create_destination_connection
    Sequel.connect(destination_database_url)
  end

  def get_count(connection, table_fullname)
    connection.fetch("SELECT count(*) from #{table_fullname};").all.first[:count]
  end

  def destination_count
    get_count(dst_conn, destination_table_fullname)
  end
end
