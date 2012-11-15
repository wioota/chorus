require 'events/base'

module Events
  class DatasetImportCreated < Base
    has_targets :source_dataset, :dataset, :workspace
    has_activities :actor, :workspace, :dataset, :source_dataset
    has_additional_data :destination_table, :reference_id, :reference_type

    def self.find_by_source(source_dataset_id, workspace_id, reference_id, reference_type)
      possible_events = where(:target1_id => source_dataset_id,
                              :workspace_id => workspace_id)

      # optimized to avoid fetching all events since the intended event is almost certainly the last event
      while event = possible_events.last
        return event if event.reference_id == reference_id && event.reference_type == reference_type
        possible_events.pop
      end
    end
  end
end