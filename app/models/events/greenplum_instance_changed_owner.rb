require 'events/base'

module Events
  class GreenplumInstanceChangedOwner < Base
    has_targets :gpdb_data_source, :new_owner
    has_activities :gpdb_data_source, :new_owner, :global
  end
end