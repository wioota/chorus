require 'events/base'

module Events
  class GreenplumInstanceChangedName < Base
    has_targets :gpdb_data_source
    has_additional_data :old_name, :new_name
    has_activities :actor, :gpdb_data_source, :global
  end
end