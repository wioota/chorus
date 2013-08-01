module Events
  class JobSucceeded < Base
    has_targets :job, :workspace
    has_activities :actor, :job, :workspace
  end
end