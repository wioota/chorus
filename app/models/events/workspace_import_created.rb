require 'events/base'

module Events
  class WorkspaceImportCreated < Base
    has_targets :source_dataset, :dataset, :workspace
    has_activities :actor, :workspace, :dataset, :source_dataset
    has_additional_data :destination_table, :reference_id, :reference_type
  end
end