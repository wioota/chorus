require 'events/base'

module Events
  class SchemaImportCreated < ImportCreatedBase
    has_targets :source_dataset, :dataset
    has_activities :actor, :dataset, :source_dataset
    has_additional_data :schema_id, :destination_table, :reference_type, :reference_id

    def schema
      @schema ||= Schema.find(schema_id)
    end

    def self.filter_for_import_events(import)
      where(:target1_id => import.source_dataset_id)
    end
  end
end