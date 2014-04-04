class JobBoss
  def self.run
    Job.ready_to_run.each(&:enqueue)

    Job.awaiting_stop.each(&:idle)
  end
end