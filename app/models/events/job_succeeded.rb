module Events
  class JobSucceeded < JobFinished
    def header
      "Job #{job.name} succeeded in workspace #{workspace.name}."
    end

    def should_notify?
      job.success_notify != 'nobody'
    end
  end
end