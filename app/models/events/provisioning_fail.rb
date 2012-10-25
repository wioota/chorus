require 'events/base'

module Events
  class ProvisioningFail < Base
    has_targets :gpdb_instance
    has_activities :actor, :gpdb_instance, :global
    has_additional_data :error_message
  end
end