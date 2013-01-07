module Events
  class NoteOnWorkspace < Note
    has_targets :workspace
    has_activities :actor, :workspace

    include_shared_search_fields(:workspace)
  end
end