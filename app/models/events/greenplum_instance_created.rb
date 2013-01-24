require 'events/base'

module Events
  class GreenplumInstanceCreated < Base
    has_targets :gpdb_data_source
    has_activities :actor, :gpdb_data_source, :global
  end
end