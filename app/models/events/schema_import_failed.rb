require 'events/base'

module Events
  class SchemaImportFailed < Base
    has_targets :source_dataset, :dataset
    has_activities :actor, :source_dataset, :dataset
    has_additional_data :destination_table, :schema_id, :error_message

    def schema
      @schema ||= Schema.find(schema_id)
    end
  end
end