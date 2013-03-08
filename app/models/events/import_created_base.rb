module Events
  class ImportCreatedBase < Base
    def self.find_for_import(import)
      if import.import_schedule_id
        reference_id = import.import_schedule_id
        reference_type = ImportSchedule.name
      else
        reference_id = import.id
        reference_type = Import.name
      end

      possible_events = filter_for_import_events(import)

      # optimized to avoid fetching all events since the intended event is almost certainly the last event
      while event = possible_events.last
        return event if event.reference_id == reference_id && event.reference_type == reference_type
        possible_events.pop
      end
    end
  end
end