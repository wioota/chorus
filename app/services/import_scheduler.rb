class ImportScheduler
  def self.run
    ImportSchedule.ready_to_run.each do |schedule|
      begin
        Import.transaction do
          import = schedule.create_import
          schedule.save! # Refresh next imported at time
          QC.enqueue("Import.run", import.id)
        end
      rescue => e
        Rails.logger.error "Import schedule #{schedule} failed to run, error was #{e.message}."
      end
    end
  end
end