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
end