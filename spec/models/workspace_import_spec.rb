require 'spec_helper'

describe WorkspaceImport do
  let(:import) { imports(:one) }

  describe 'associations' do
    it { should belong_to :workspace }
    it { should belong_to :import_schedule }
  end

  describe 'creating' do
    let(:source_dataset) { datasets(:oracle_table) }
    let(:workspace) { workspaces(:public) }
    let(:user) { users(:owner) }

    it 'creates a WorkspaceImportCreated event' do
      expect {
        import = WorkspaceImport.new
        import.to_table = 'the_new_table'
        import.source_dataset = source_dataset
        import.workspace = workspace
        import.user = user
        import.save!(:validate => false)
      }.to change(Events::WorkspaceImportCreated, :count).by(1)

      event = Events::WorkspaceImportCreated.last
      event.actor.should == user
      event.dataset.should be_nil
      event.source_dataset.should == source_dataset
      event.workspace.should == workspace
      event.destination_table.should == 'the_new_table'
    end
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