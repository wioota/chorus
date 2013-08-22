module Events
  class JobFailed < JobFinished

    def header
      "Job #{job.name} failed in workspace #{workspace.name}."
    end
  end
end