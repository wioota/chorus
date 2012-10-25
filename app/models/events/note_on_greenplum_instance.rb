module Events
  class NoteOnGreenplumInstance < Note
    has_targets :gpdb_instance
    has_activities :actor, :gpdb_instance, :global
  end
end