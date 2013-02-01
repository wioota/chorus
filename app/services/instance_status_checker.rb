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
    @data_source.version = get_data_source_version
    @data_source.state = "online"
  rescue => e
    Chorus.log_error "Could not check status: #{e}: #{e.message} on #{e.backtrace[0]}"
    @data_source.state = "offline"
  end

  private

  def get_data_source_version
    if @data_source.is_a?(HadoopInstance)
      Hdfs::QueryService.data_source_version(@data_source)
    else
      @data_source.connect_as_owner.version
    end
  end

  def should_check
    return true if @data_source.state == 'online' || @data_source.last_checked_at.blank?

    Time.current - @data_source.last_checked_at > 2.hours #except for authentication failures
  end
end

