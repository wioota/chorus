require 'error_logger'

class ImportScheduler
  def self.run
    ImportSchedule.ready_to_run.each do |schedule|
      begin
        Import.transaction do
          import = schedule.create_import
          if schedule.save
            QC.enqueue_if_not_queued("ImportExecutor.run", import.id)
          else
            Events::DatasetImportFailed.by(import.user).add(
                :workspace => import.workspace,
                :destination_table => import.to_table,
                :error_objects => schedule.errors,
                :source_dataset => import.source_dataset,
                :dataset => import.sandbox.datasets.find_by_name(import.to_table)
            )
            schedule.set_next_import
          end
        end
      rescue => e
        Chorus.log_error "Import schedule with ID #{schedule.id} failed with error '#{e}'."
      end
    end
  end
end
