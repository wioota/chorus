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
end