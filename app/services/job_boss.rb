class JobBoss
  def self.run
    Job.ready_to_run.each { |job| job.valid? ? job.enqueue : job.disable }

    Job.awaiting_stop.each(&:idle)
  end
end
