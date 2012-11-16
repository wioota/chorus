class ImportExecutor < DelegateClass(Import)
  delegate :sandbox, :to => :workspace
  
  def self.run(import_id)
    import = Import.find(import_id)
    ImportExecutor.new(import).run
  end

  def run
    import_attributes = attributes.symbolize_keys
    import_attributes.slice!(:workspace_id, :to_table, :new_table, :sample_count, :truncate)

    GpTableCopier.run_import(source_dataset.id, user.id, import_attributes)

    import_schedule.update_attribute(:destination_dataset_id, destination_dataset_id) if new_table? && import_schedule
    import_schedule.update_attribute(:new_table, false) if new_table? && import_schedule

    mark_import(true)
    create_success_event
  rescue => e
    mark_import(false)
    create_failed_event(e.message)
    raise e
  end

  def mark_import(success)
    self.success = success
    self.finished_at = Time.now

    if success
      Dataset.refresh(sandbox.gpdb_instance.account_for_user!(user), sandbox)
      dst_table = sandbox.datasets.find_by_name!(to_table)
      self.destination_dataset_id = dst_table.id
    end

    save!
  end

  def create_success_event
    dst_table = sandbox.datasets.find_by_name!(to_table)

    event = Events::DatasetImportSuccess.by(user).add(
        :workspace => workspace,
        :dataset => dst_table,
        :source_dataset => source_dataset
    )

    Notification.create!(:recipient_id => user.id, :event_id => event.id)

    update_import_created_event
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
    event = Events::DatasetImportFailed.by(user).add(
        :workspace => workspace,
        :destination_table => to_table,
        :error_message => error_message,
        :source_dataset => source_dataset,
        :dataset => sandbox.datasets.find_by_name(to_table)
    )

    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end
end