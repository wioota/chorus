require 'error_logger'

class InstanceStatusChecker
  def self.check_all
    check_each_data_source(GpdbDataSource.all)
    check_each_data_source(OracleDataSource.all)
    check_each_data_source(HadoopInstance.all)
  end

  def self.check(data_source)
    new(data_source).check
  end

  def initialize(data_source)
    @data_source = data_source
  end

  def check
    if @data_source.is_a?(HadoopInstance)
      check_hdfs_data_source
    elsif @data_source.is_a?(OracleDataSource)
      check_oracle_data_source
    else
      check_gpdb_data_source
    end
    @data_source.touch
    @data_source.save!
  end

  def check_hdfs_data_source
    check_with_exponential_backoff do
      begin
        version = Hdfs::QueryService.data_source_version(@data_source)
        @data_source.version = version
        @data_source.state = "online"
      rescue => e
        @data_source.state = "offline"
      end
    end
  end

  def check_gpdb_data_source
    check_with_exponential_backoff do
      begin
        Gpdb::ConnectionBuilder.connect!(@data_source, @data_source.owner_account) do |conn|
          @data_source.state = "online"
          version_string = conn.exec_query("select version()")[0]["version"]
          # if the version string looks like this:
          # PostgreSQL 9.2.15 (Greenplum Database 4.1.1.2 build 2) on i386-apple-darwin9.8.0 ...
          # then we just want "4.1.1.2"
          @data_source.version = version_string.match(/Greenplum Database ([\d\.]*)/)[1]
        end
      rescue
        @data_source.version = "Error"
        @data_source.state = "offline"
      end
    end
  end

  def check_oracle_data_source
    check_with_exponential_backoff do
      begin
        @data_source.version = @data_source.connect_with(@data_source.owner_account).version
        @data_source.state = "online"
      rescue OracleConnection::DatabaseError => e
        @data_source.version = "Error"
        @data_source.state = "offline"
      end
    end
  end

  private

  def self.check_each_data_source(data_sources)
    data_sources.each do |data_source|
      check(data_source)
    end
  end

  def downtime_before_last_check
    @data_source.last_checked_at - @data_source.last_online_at
  end

  def maximum_check_interval
    1.day
  end

  def next_check_time
    return 1.minute.ago if @data_source.last_online_at.blank?
    next_check_at = @data_source.last_online_at + downtime_before_last_check * 2
    must_check_by = @data_source.last_checked_at + maximum_check_interval
    [next_check_at, must_check_by].min
  end

  def check_with_exponential_backoff(&block)
    return if Time.current < next_check_time
    @data_source.touch(:last_checked_at)
    yield block
    if @data_source.state == 'online'
      @data_source.last_online_at = @data_source.last_checked_at
    end
  end
end

