require 'events/base'

module Events
  class GreenplumInstanceChangedOwner < Base
    has_targets :gpdb_instance, :new_owner
    has_activities :gpdb_instance, :new_owner, :global
  end
end