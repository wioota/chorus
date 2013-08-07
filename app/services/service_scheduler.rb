class ServiceScheduler
  include Clockwork

  def initialize
    every(ChorusConfig.instance['instance_poll_interval_minutes'].minutes, 'DataSourceStatusChecker.check_all') do
      QC.enqueue_if_not_queued("DataSourceStatusChecker.check_all")
    end

    every(ChorusConfig.instance['delete_unimported_csv_files_interval_hours'].hours, 'CsvFile.delete_old_files!') do
      QC.enqueue_if_not_queued("CsvFile.delete_old_files!")
    end

    every(24.hours, 'OrphanCleaner.clean') do
      QC.enqueue_if_not_queued("OrphanCleaner.clean")
    end

    every(ChorusConfig.instance['reindex_search_data_interval_hours'].hours, 'SolrIndexer.refresh_external_data') do
      QC.enqueue_if_not_queued("SolrIndexer.refresh_external_data")
    end

    every(ChorusConfig.instance['reset_counter_cache_interval_hours'].hours, 'Tag.reset_all_counters') do
      QC.enqueue_if_not_queued("Tag.reset_all_counters")
    end

    every(ChorusConfig.instance['clean_expired_sessions_interval_hours'].hours, 'Session.remove_expired_sessions') do
      QC.enqueue_if_not_queued("Session.remove_expired_sessions")
    end

    every(1.minute, 'JobBoss.run') do
      JobBoss.run
    end

    end

  def job_named(job)
    @@events.find { |event|
      event.job == job
    }
  end

  def self.run
    ServiceScheduler.new.run
  end
end