require 'events/base'

module Events
  class SchemaImportCreated < Base
    has_targets :dataset, :source_dataset
    has_activities :actor, :dataset, :source_dataset
    has_additional_data :schema_id, :destination_table

    def schema
      @schema ||= Schema.find(schema_id)
    end
  end
end