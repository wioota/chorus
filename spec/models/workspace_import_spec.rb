require 'spec_helper'

describe WorkspaceImport do
  let(:import) { imports(:one) }

  describe 'associations' do
    it { should belong_to :workspace }
    it { should belong_to :import_schedule }
  end

  describe '#schema' do
    it 'is the sandbox of the workspace' do
      import.schema.should == import.workspace.sandbox
    end
  end

  describe '#create_passed_event_and_notification' do
    it 'creates a WorkspaceImportSuccess event' do
      expect {
        import.create_passed_event_and_notification
      }.to change(Events::WorkspaceImportSuccess, :count).by(1)
    end

    it 'creates a notification for the import creator' do
      expect {
        import.create_passed_event_and_notification
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      notification.recipient_id.should == import.user_id
      notification.event_id.should == Events::WorkspaceImportSuccess.last.id
    end
  end

  describe '#create_failed_event_and_notification' do
    it 'creates a WorkspaceImportFailed event' do
      expect {
        import.create_failed_event_and_notification("message")
      }.to change(Events::WorkspaceImportFailed, :count).by(1)
      event = Events::WorkspaceImportFailed.last

      event.actor.should == import.user
      event.error_message.should == "message"
      event.workspace.should == import.workspace
      event.source_dataset.should == import.source_dataset
      event.destination_table.should == import.to_table
    end

    it 'creates a notification for the import creator' do
      expect {
        import.create_failed_event_and_notification("message")
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      notification.recipient_id.should == import.user_id
      notification.event_id.should == Events::WorkspaceImportFailed.last.id
    end
  end
end