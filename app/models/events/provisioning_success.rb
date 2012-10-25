require 'events/base'

module Events
  class ProvisioningSuccess < Base
    has_targets :gpdb_instance
    has_activities :actor,:gpdb_instance, :global
  end
end