class SchemaImport < Import
  belongs_to :schema
  validates :schema, :presence => true

  def create_passed_event_and_notification
    event = Events::SchemaImportSuccess.by(user).add(
      :dataset => destination_dataset,
      :source_dataset => source_dataset
    )
    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def create_failed_event_and_notification(error_message)
    event = Events::SchemaImportFailed.by(user).add(
      :destination_table => to_table,
      :error_message => error_message,
      :source_dataset => source_dataset,
      :dataset => schema.datasets.find_by_name(to_table),
      :schema_id => schema.id
    )
    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end
end