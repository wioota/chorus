require 'spec_helper'

describe WorkspaceImport do
  let(:import) { imports(:one) }
  let(:user) { import.user }

  describe 'associations' do
    it { should belong_to(:scoped_workspace).class_name("Workspace") }
    it { should belong_to :import_schedule }
  end

  describe 'creating' do
    let(:source_dataset) { datasets(:oracle_table) }
    let(:workspace) { workspaces(:public) }

    it 'creates a WorkspaceImportCreated event' do
      import = WorkspaceImport.new
      import.to_table = 'the_new_table'
      import.source_dataset = source_dataset
      import.workspace = workspace
      import.user = user
      expect {
        import.save!(:validate => false)
      }.to change(Events::WorkspaceImportCreated, :count).by(1)

      event = Events::WorkspaceImportCreated.last
      event.actor.should == user
      event.dataset.should be_nil
      event.reference_id.should == import.id
      event.reference_type.should == 'Import'
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

  describe "#cancel" do
    let(:source_connection) { Object.new }
    let(:destination_connection) { Object.new }
    let(:destination_table_name) { import.to_table }
    let(:sandbox) { import.schema }
    let(:import) do
      imp = imports(:now)
      imp.update_attribute(:to_table, datasets(:table).name)
      imp
    end

    let!(:import_created_event) do
      Events::WorkspaceImportCreated.by(user).add(
        :workspace => import.workspace,
        :dataset => nil,
        :destination_table => destination_table_name,
        :reference_id => import.id,
        :reference_type => Import.name,
        :source_dataset => import.source_dataset
      )
    end

    before do
      stub(import).log.with_any_args
      stub(import.source_dataset).connect_as(user) { source_connection }
      stub(import.schema).connect_as(user) { destination_connection }

      stub(source_connection).running?.with_any_args { true }
      stub(destination_connection).running?.with_any_args { true }
      mock(source_connection).kill("pipe%_#{import.created_at.to_i}_#{import.id}_w")
      mock(destination_connection).kill("pipe%_#{import.created_at.to_i}_#{import.id}_r")
      any_instance_of(Schema) do |schema|
        stub(schema).refresh_datasets.with_any_args do
          FactoryGirl.create(:gpdb_table, :name => destination_table_name, :schema => sandbox)
        end
      end
    end

    it 'removes the named pipe from disk' do
      dir = ChorusConfig.instance['gpfdist.data_dir']
      FileUtils.mkdir_p dir
      pipe_file = File.join(dir, "pipe_with_some_extra_stuff_#{import.created_at.to_i}_#{import.id}")
      FileUtils.touch pipe_file
      import.cancel(true)
      File.exists?(pipe_file).should be_false
    end

    describe "when the import is marked as successful" do
      let(:cancel_import) do
        import.cancel(true)
      end

      it_behaves_like :import_succeeds, :cancel_import
    end

    describe "when the import is marked as failed with a message" do
      let(:cancel_import) do
        import.cancel(false, "some crazy error")
      end

      it_behaves_like :import_fails_with_message, :cancel_import, "some crazy error"
    end
  end
end