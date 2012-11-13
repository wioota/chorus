require 'events/base'

module Events
  class WorkspaceDeleted < Base
    has_targets :workspace
    has_activities :actor, :global

    def create_activity(entity_name)
      unless entity_name == :global
        super entity_name
        return
      end

      entity = send(:workspace)
      Activity.global.create!(:event => self) if entity.public?
    end
  end
end
