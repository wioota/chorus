class WorkspaceImport < Import
  belongs_to :workspace
  validates :workspace, :presence => true
  validate :workspace_is_not_archived

  def schema
    workspace.sandbox
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
end