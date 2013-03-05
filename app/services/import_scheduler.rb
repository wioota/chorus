require 'error_logger'

class ImportScheduler
  def self.run
    ImportSchedule.ready_to_run.each do |schedule|
      begin
        import = schedule.create_import
        schedule.save! #update next_import_at
        QC.enqueue_if_not_queued("ImportExecutor.run", import.id)
      rescue => e
        begin
          schedule.save(:validate => false) #update next_import_at, and then fill errors
        rescue => e
          Chorus.log_error "Schedule could not be saved with error #{e}."
        end

        event_args = {
            :workspace => schedule.workspace,
            :destination_table => schedule.to_table,
            :source_dataset => schedule.source_dataset,
            :dataset => schedule.schema.datasets.find_by_name(schedule.to_table)
        }
        if schedule.errors.blank?
          event_args.merge! :error_message => e.message
        else
          event_args.merge! :error_objects => schedule.errors
        end
        Events::WorkspaceImportFailed.by(schedule.user).add(event_args)
        Chorus.log_error "Import schedule with ID #{schedule.id} failed with error '#{e}'."
      end
    end
  end
end
