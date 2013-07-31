class JobBoss
  def self.run
    Job.ready_to_run.each(&:enqueue)
  end
end