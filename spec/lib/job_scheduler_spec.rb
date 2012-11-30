require 'spec_helper'
require 'job_scheduler'

describe JobScheduler do
  let(:job_scheduler) { JobScheduler.new }
  describe "InstanceStatusChecker.check" do
    it "runs every ChorusConfig.instance['instance_poll_interval_minutes'] minutes" do
      job_scheduler.job_named('InstanceStatusChecker.check').period.should == ChorusConfig.instance['instance_poll_interval_minutes'].minutes
    end

    it "enqueues the 'InstanceStatusChecker.check' job in QC" do
      mock(QC.default_queue).enqueue_if_not_queued("InstanceStatusChecker.check")
      job_scheduler.job_named('InstanceStatusChecker.check').run(Time.current)
    end
  end

  describe "CsvFile.delete_old_files!" do
    it "runs every ChorusConfig.instance['delete_unimported_csv_files_interval_hours'] hours" do
      job_scheduler.job_named('CsvFile.delete_old_files!').period.should == ChorusConfig.instance['delete_unimported_csv_files_interval_hours'].hours
    end

    it "enqueues the 'CsvFile.delete_old_files!' job in QC" do
      mock(QC.default_queue).enqueue_if_not_queued("CsvFile.delete_old_files!")
      job_scheduler.job_named('CsvFile.delete_old_files!').run(Time.current)
    end
  end

  describe "SolrIndexer.refresh_external_data" do
    it "runs every ChorusConfig.instance['reindex_search_data_interval_hours'] hours" do
      job_scheduler.job_named('SolrIndexer.refresh_external_data').period.should == ChorusConfig.instance['reindex_search_data_interval_hours'].hours
    end

    it "enqueues the 'SolrIndexer.refresh_external_data' job in QC" do
      mock(QC.default_queue).enqueue_if_not_queued("SolrIndexer.refresh_external_data")
      job_scheduler.job_named('SolrIndexer.refresh_external_data').run(Time.current)
    end
  end

  describe "ImportScheduler" do
    it "runs every minute" do
      job_scheduler.job_named('ImportScheduler.run').period.should == 1.minute
    end

    it "runs the ImportScheduler in the same thread" do
      mock(ImportScheduler).run
      job_scheduler.job_named('ImportScheduler.run').run(Time.current)
    end
  end

  describe "JobScheduler.run" do
    it "builds a JobScheduler and then runs it starts the clockwork" do
      built = false
      any_instance_of(JobScheduler) do |js|
        mock(js).run
        built = true
      end
      JobScheduler.run
      built.should be_true
    end
  end
end

describe QC do
  it "adds a timestamps to the data" do
    Timecop.freeze(Time.current) do
      mock(Scrolls).log(hash_including({:timestamp => Time.current.to_s})).times(any_times)
      QC.log(:message => "Rome is burning")
    end
  end
end

module Clockwork
  class Event
    attr_reader :period
  end
end