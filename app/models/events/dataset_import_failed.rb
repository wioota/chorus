require 'events/base'

module Events
  class DatasetImportFailed < Base
    has_targets :dataset, :source_dataset, :workspace
    has_activities :actor, :workspace, :source_dataset, :dataset
    has_additional_data :destination_table, :error_message
  end
end
