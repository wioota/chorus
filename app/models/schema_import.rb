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
end