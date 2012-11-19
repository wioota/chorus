require 'lib/error_logger'

class ImportScheduler
  def self.run
    ImportSchedule.ready_to_run.each do |schedule|
      begin
        Import.transaction do
          import = schedule.create_import
          schedule.save! # Refresh next imported at time
          QC.enqueue("ImportExecutor.run", import.id)
        end
      rescue => e
        Chorus.log_error "Import schedule with ID #{schedule.id} failed with error '#{e}'."
      end
    end
  end
end
