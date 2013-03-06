require 'spec_helper'

describe SchemaImport do
  let(:import) { imports(:oracle) }

  describe 'associations' do
    it { should belong_to :schema }
  end

  describe '#create_passed_event_and_notification' do
    it 'creates a SchemaImportSuccess event' do
      expect {
        import.create_passed_event_and_notification
      }.to change(Events::SchemaImportSuccess, :count).by(1)
    end

    it 'creates a notification for the import creator' do
      expect {
        import.create_passed_event_and_notification
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      notification.recipient_id.should == import.user_id
      notification.event_id.should == Events::SchemaImportSuccess.last.id
    end
  end

  describe '#create_failed_event_and_notification' do
    it 'creates a SchemaImportFailed event' do
      expect {
        import.create_failed_event_and_notification("message")
      }.to change(Events::SchemaImportFailed, :count).by(1)
      event = Events::SchemaImportFailed.last

      event.actor.should == import.user
      event.error_message.should == "message"
      event.schema.should == import.schema
      event.source_dataset.should == import.source_dataset
      event.destination_table.should == import.to_table
    end

    it 'creates a notification for the import creator' do
      expect {
        import.create_failed_event_and_notification("message")
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      notification.recipient_id.should == import.user_id
      notification.event_id.should == Events::SchemaImportFailed.last.id
    end
  end
end