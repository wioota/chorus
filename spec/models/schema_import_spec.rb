require 'spec_helper'

describe SchemaImport do
  let(:import) { imports(:oracle) }

  describe 'associations' do
    it { should belong_to :schema }
  end

  describe 'creating' do
    let(:source_dataset) { datasets(:oracle_table) }
    let(:schema) { schemas(:default) }
    let(:user) { users(:owner) }

    it 'creates a SchemaImportCreated event' do
      expect {
        import = SchemaImport.new
        import.to_table = 'the_new_table'
        import.source_dataset = source_dataset
        import.schema = schema
        import.user = user
        import.save!(:validate => false)
      }.to change(Events::SchemaImportCreated, :count).by(1)

      event = Events::SchemaImportCreated.last
      event.actor.should == user
      event.dataset.should be_nil
      event.source_dataset.should == source_dataset
      event.schema.should == schema
      event.destination_table.should == 'the_new_table'
    end
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