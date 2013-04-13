class SchemaImport < Import
  belongs_to :schema
  validates :schema, :presence => true

  def create_import_event
    destination_table = schema.datasets.tables.find_by_name(to_table)
    created_event_class.by(user).add(
      {
        :source_dataset => source_dataset,
        :schema_id => schema.id,
        :destination_table => to_table,
        :dataset => destination_table,
        :reference_id => id,
        :reference_type => 'Import'
      }
    )
  end

  def created_event_class
    Events::SchemaImportCreated
  end

  def success_event_class
    Events::SchemaImportSuccess
  end

  def failed_event_class
    Events::SchemaImportFailed
  end

  def copier_class
    OracleTableCopier
  end

  def create_passed_event_and_notification
    event = success_event_class.by(user).add(
      :dataset => destination_dataset,
      :source_dataset => source_dataset
    )
    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def create_failed_event_and_notification(error_message)
    event = failed_event_class.by(user).add(
      :destination_table => to_table,
      :error_message => error_message,
      :source_dataset => source_dataset,
      :dataset => schema.datasets.find_by_name(to_table),
      :schema_id => schema.id
    )
    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def cancel(success, message = nil)
    super

    connection = schema.connect_as(user)
    CancelableQuery.new(connection, handle, user).cancel
  end
end