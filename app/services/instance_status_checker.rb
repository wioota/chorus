require 'error_logger'

class InstanceStatusChecker
  def self.check_all
    DataSource.find_each { |ds| self.check(ds) }
    HadoopInstance.find_each { |instance| self.check(instance) }
  end

  def self.check(data_source)
    new(data_source).check
  end

  def initialize(data_source)
    @data_source = data_source
  end

  def check
    return unless should_check

    poll_data_source

    @data_source.touch(:last_checked_at)
    if @data_source.state == 'online'
      @data_source.touch(:last_online_at)
    end
    @data_source.save!
  end

  def poll_data_source
    if @data_source.is_a?(HadoopInstance)
      check_hdfs_data_source
    elsif @data_source.is_a?(OracleDataSource)
      check_oracle_data_source
    else
      check_gpdb_data_source
    end
  end

  private

  def check_hdfs_data_source
    version = Hdfs::QueryService.data_source_version(@data_source)
    @data_source.version = version
    @data_source.state = "online"
  rescue => e
    @data_source.state = "offline"
  end

  def check_gpdb_data_source
    Gpdb::ConnectionBuilder.connect!(@data_source, @data_source.owner_account) do |conn|
      @data_source.state = "online"
      version_string = conn.exec_query("select version()")[0]["version"]
      # if the version string looks like this:
      # PostgreSQL 9.2.15 (Greenplum Database 4.1.1.2 build 2) on i386-apple-darwin9.8.0 ...
      # then we just want "4.1.1.2"
      @data_source.version = version_string.match(/Greenplum Database ([\d\.]*)/)[1]
    end
  rescue => e
    @data_source.version = "Error"
    @data_source.state = "offline"
  end

  def check_oracle_data_source
    @data_source.version = @data_source.connect_with(@data_source.owner_account).version
    @data_source.state = "online"
  rescue OracleConnection::DatabaseError => e
    @data_source.version = "Error"
    @data_source.state = "offline"
  end

  def should_check
    return true if @data_source.state == 'online' || @data_source.last_checked_at.blank?

    Time.current - @data_source.last_checked_at > 2.hours #except for authentication failures
  end
end

