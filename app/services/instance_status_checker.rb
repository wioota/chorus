class InstanceStatusChecker
  def self.check_all
    DataSource.find_each { |ds| self.check(ds) }
    HdfsDataSource.find_each { |instance| self.check(instance) }
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

  private

  def poll_data_source
    @data_source.version = get_data_source_version
    @data_source.state = "online"
  rescue DataSourceConnection::Error => e
    Chorus.log_error "Could not check status: #{e}: #{e.message} on #{e.backtrace[0]}"
    @data_source.state = e.error_type == :INVALID_PASSWORD ? "unauthorized" : "offline"
  rescue => e
    Chorus.log_error "Could not check status: #{e}: #{e.message} on #{e.backtrace[0]}"
    @data_source.state = "offline"
  end

  def get_data_source_version
    if @data_source.is_a?(HdfsDataSource)
      @data_source.version
    else
      @data_source.connect_as_owner.version
    end
  end

  def should_check
    return true if @data_source.last_checked_at.blank?

    time_between_checks =
        case @data_source.state
          when 'offline' then
            2.hours
          when 'unauthorized' then
            24.hours
          else
            0  #still shouldn't check more often than instance_poll_interval_minutes
        end
    Time.current - @data_source.last_checked_at > time_between_checks
  end
end

