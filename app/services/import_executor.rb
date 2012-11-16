class ImportExecutor < DelegateClass(Import)
  delegate :sandbox, :to => :workspace

  def self.run(import_id)
    import = Import.find(import_id)
    ImportExecutor.new(import).run
  end

  def run
    import_attributes = attributes.symbolize_keys.slice(:workspace_id, :to_table, :new_table, :sample_count, :truncate)

    GpTableCopier.run_import(source_dataset.id, user.id, import_attributes)

    # update rails db for new dataset
    Dataset.refresh(sandbox.gpdb_instance.account_for_user!(user), sandbox)

    update_status :passed

  rescue => e
    update_status :failed, e
    raise
  end

  private

  def update_status(status, exception = nil)
    passed = (status == :passed)

    touch(:finished_at)
    self.success = passed
    save! # this also updates destination_dataset_id

    if passed
      event = create_passed_event_and_notification
      update_import_created_event
      import_schedule.update_attributes({:new_table => false}) if import_schedule
    else
      event = create_failed_event exception.message
    end

    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def create_passed_event_and_notification
    event = Events::DatasetImportSuccess.by(user).add(
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
      import_created_event.dataset = sandbox.datasets.find_by_name!(to_table)
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
        :workspace => workspace,
        :destination_table => to_table,
        :error_message => error_message,
        :source_dataset => source_dataset,
        :dataset => sandbox.datasets.find_by_name(to_table)
    )
  end
end