require 'events/base'

module Events
  class GreenplumInstanceChangedName < Base
    has_targets :gpdb_instance
    has_additional_data :old_name, :new_name
    has_activities :actor, :gpdb_instance, :global
  end
end