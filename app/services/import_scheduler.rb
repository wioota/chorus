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

        Events::DatasetImportFailed.by(schedule.user).add(
            :workspace => schedule.workspace,
            :destination_table => schedule.to_table,
            :error_objects => schedule.errors,
            :source_dataset => schedule.source_dataset,
            :dataset => schedule.sandbox.datasets.find_by_name(schedule.to_table)
        )
        Chorus.log_error "Import schedule with ID #{schedule.id} failed with error '#{e}'."
      end
    end
  end
end
