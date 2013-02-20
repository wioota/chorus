require 'sequel/no_core_ext'

class ImportExecutor < DelegateClass(Import)
  delegate :sandbox, :to => :workspace

  def self.run(import_id)
    import = Import.find(import_id)
    ImportExecutor.new(import).run if import.success.nil?
  end

  def self.cancel(import, success, message = nil)
    ImportExecutor.new(import).cancel(success, message)
  end

  def run
    touch(:started_at)
    raise "Destination workspace #{workspace_with_deleted.name} has been deleted" if workspace_with_deleted.deleted?
    raise "Original source dataset #{source_dataset_with_deleted.scoped_name} has been deleted" if source_dataset_with_deleted.deleted?
    table_copier.new(import_attributes).start
    update_status :passed
  rescue => e
    update_status :failed, e.message
    raise
  end

  def cancel(success, message = nil)
    update_status(success ? :passed : :failed, message)
    ImportTerminator.terminate(__getobj__)
  end

  private

  def table_copier
    if source_dataset.class.name =~ /^Oracle/
      OracleTableCopier
    elsif source_dataset.database != sandbox.database
      CrossDatabaseTableCopier
    else
      TableCopier
    end
  end

  def import_attributes
    {
        :source_dataset => source_dataset,
        :destination_schema => sandbox,
        :destination_table_name => to_table,
        :user => user,
        :sample_count => sample_count,
        :truncate => truncate,
        :pipe_name => "#{created_at.to_i}_#{id}"
    }
  end

  def refresh_schema
    # update rails db for new dataset
    destination_account = sandbox.database.data_source.account_for_user!(user)
    sandbox.refresh_datasets(destination_account) rescue ActiveRecord::JDBCError
  end

  def update_status(status, message = nil)
    return unless reload.success.nil?

    passed = (status == :passed)

    touch(:finished_at)
    self.success = passed
    save(:validate => false)

    if passed
      refresh_schema
      set_destination_dataset_id
      save(:validate => false)

      event = create_passed_event_and_notification
      update_import_created_event
      import_schedule.update_attributes({:new_table => false}) if import_schedule
    else
      event = create_failed_event message
    end

    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def create_passed_event_and_notification
    Events::DatasetImportSuccess.by(user).add(
        :workspace => workspace,
        :dataset => destination_dataset,
        :source_dataset => source_dataset
    )
  end

  def update_import_created_event
    if import_schedule_id
      reference_id = import_schedule_id
      reference_type = "ImportSchedule"
    else
      reference_id = id
      reference_type = "Import"
    end

    import_created_event = find_dataset_import_created_event(source_dataset_id, workspace_id, reference_id, reference_type)

    if import_created_event
      import_created_event.dataset = find_destination_dataset
      import_created_event.save!
    end
  end

  def find_dataset_import_created_event(source_dataset_id, workspace_id, reference_id, reference_type)
    possible_events = Events::DatasetImportCreated.where(:target1_id => source_dataset_id,
                                                         :workspace_id => workspace_id)

    # optimized to avoid fetching all events since the intended event is almost certainly the last event
    while event = possible_events.last
      return event if event.reference_id == reference_id && event.reference_type == reference_type
      possible_events.pop
    end
  end

  def create_failed_event(error_message)
    Events::DatasetImportFailed.by(user).add(
        :workspace => workspace_with_deleted,
        :destination_table => to_table,
        :error_message => error_message,
        :source_dataset => source_dataset,
        :dataset => workspace_with_deleted.sandbox.datasets.find_by_name(to_table)
    )
  end
end