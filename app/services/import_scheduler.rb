class ImportScheduler
  def self.run
    ImportSchedule.ready_to_run.each do |schedule|
      begin
        Import.transaction do
          import = schedule.build_import
          import.save!
          schedule.last_scheduled_at = Time.current
          schedule.save!
          QC.enqueue("Import.run", import.id)
        end
      rescue Exception => e
        Rails.logger.error "Import schedule #{schedule} failed to run."
      end
    end
  end
end