module Events
  class JobSucceeded < JobFinished

    def header
      "Job #{job.name} succeeded in workspace #{workspace.name}."
    end
  end
end