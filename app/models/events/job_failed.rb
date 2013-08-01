module Events
  class JobFailed < Base
    has_targets :job, :workspace
    has_activities :actor, :job, :workspace
  end
end