module Events
  class JobFailed < JobFinished
    def header
      "Job #{job.name} failed in workspace #{workspace.name}."
    end

    def should_notify?
      job.failure_notify != 'nobody'
    end
  end
end