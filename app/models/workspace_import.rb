class WorkspaceImport < Import
  belongs_to :workspace
  validates :workspace, :presence => true
  validate :workspace_is_not_archived

  def schema
    workspace.sandbox
  end

  def create_import_event
    destination_table = schema.datasets.tables.find_by_name(to_table)
    Events::WorkspaceImportCreated.by(user).add(
      :workspace => workspace,
      :source_dataset => source_dataset,
      :dataset => destination_table,
      :destination_table => to_table,
      :reference_id => id,
      :reference_type => 'Import'
    )
  end

  def created_event_class
    Events::WorkspaceImportCreated
  end

  def create_passed_event_and_notification
    event = Events::WorkspaceImportSuccess.by(user).add(
      :workspace => workspace,
      :dataset => destination_dataset,
      :source_dataset => source_dataset
    )
    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def create_failed_event_and_notification(error_message)
    event = Events::WorkspaceImportFailed.by(user).add(
      :workspace => workspace_with_deleted,
      :destination_table => to_table,
      :error_message => error_message,
      :source_dataset => source_dataset,
      :dataset => workspace_with_deleted.sandbox.datasets.find_by_name(to_table)
    )
    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def cancel(success, message = nil)
    super

    read_pipe_searcher = "pipe%_#{handle}_r"
    read_connection = schema.connect_as(user)
    if read_connection.running? read_pipe_searcher
      log "Found running reader on database #{schema.database.name} on instance #{schema.data_source.name}, killing it"
      read_connection.kill read_pipe_searcher
    else
      log "Could not find running reader on database #{schema.database.name} on instance #{schema.data_source.name}"
    end

    write_pipe_searcher = "pipe%_#{handle}_w"
    write_connection = source_dataset.connect_as(user)
    if write_connection.running? write_pipe_searcher
      log "Found running writer on database #{source_dataset.schema.database.name} on data source #{source_dataset.data_source.name}, killing it"
      write_connection.kill write_pipe_searcher
    else
      log "Could not find running writer on database #{source_dataset.schema.database.name} on data source #{source_dataset.data_source.name}"
    end

    if named_pipe
      log "Removing named pipe #{named_pipe}"
      FileUtils.rm_f named_pipe
    end
  end
end
