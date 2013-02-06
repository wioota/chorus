require 'spec_helper'

describe ImportExecutor do
  let(:user) { users(:owner) }
  let(:source_dataset) { datasets(:table) }
  let(:workspace) { workspaces(:public) }
  let(:sandbox) { workspace.sandbox }
  let(:destination_table_name) { "dst_table" }
  let(:database_url) { Gpdb::ConnectionBuilder.url(sandbox.database, account) }
  let(:account) { sandbox.data_source.account_for_user!(user) }

  let!(:dataset_import_created_event) do
    Events::DatasetImportCreated.by(user).add(
        :workspace => workspace,
        :dataset => nil,
        :destination_table => destination_table_name,
        :reference_id => import.id,
        :reference_type => "Import",
        :source_dataset => source_dataset
    )
  end

  let(:import) do
    FactoryGirl.build(:import,
                      :user => user,
                      :workspace => workspace,
                      :to_table => destination_table_name,
                      :source_dataset => source_dataset).tap {|i| i.save(:validate => false)}
  end
  let(:import_failure_message) { "" }

  shared_examples_for :it_generates_no_events do |trigger|
    it "generates no new events or notifications" do
      expect {
        expect {
          send(trigger)
        }.not_to change(Events::Base, :count)
      }.not_to change(Notification, :count)
    end
  end

  shared_examples_for :it_generates_no_events_when_already_marked_as_passed_or_failed do |trigger|
    context "when the import is already marked as passed" do
      before do
        import.success = true
        import.save!
      end
      it_behaves_like :it_generates_no_events, trigger
    end

    context "when the import is already marked as failed" do
      before do
        import.success = false
        import.save!
      end
      it_behaves_like :it_generates_no_events, trigger
    end
  end

  shared_examples_for :it_succeeds do | trigger |
    context "when import is successful" do
      it "creates a DatasetImportSuccess" do
        expect {
          send(trigger)
        }.to change(Events::DatasetImportSuccess, :count).by(1)

        event = Events::DatasetImportSuccess.last
        event.actor.should == user
        event.dataset.name.should == destination_table_name
        event.dataset.schema.should == sandbox
        event.workspace.should == workspace
        event.source_dataset.should == source_dataset
      end

      it "creates a notification" do
        expect {
          send(trigger)
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        notification.recipient_id.should == user.id
        notification.event_id.should == Events::DatasetImportSuccess.last.id
      end

      it "marks the import as success" do
        send(trigger)
        import.reload
        import.success.should be_true
        import.finished_at.should_not be_nil
      end

      it "refreshes the schema" do
        refreshed = false
        any_instance_of(Schema) do |schema|
          stub(schema).refresh_datasets(sandbox.database.data_source.account_for_user!(user)) { refreshed = true }
        end
        send(trigger)
        refreshed.should == true
      end

      it "updates the destination dataset id" do
        send(trigger)
        import.reload
        import.success.should be_true
        import.destination_dataset_id.should_not be_nil
      end

      it "sets the dataset attribute of the DATASET_IMPORT_CREATED event" do
        send(trigger)
        event = dataset_import_created_event.reload
        event.dataset.name.should == destination_table_name
        event.dataset.schema.should == sandbox
      end

      it_behaves_like :it_generates_no_events_when_already_marked_as_passed_or_failed, trigger

      context "when the import is a scheduled import" do
        let(:import_schedule_id) { 1234 }

        before do
          dataset_import_created_event.reference_id = import_schedule_id
          dataset_import_created_event.reference_type = 'ImportSchedule'
          dataset_import_created_event.save!
          import.import_schedule_id = import_schedule_id
          import.save!
        end

        it "still sets the dataset attribute of the DATASET_IMPORT_CREATED event" do
          send(trigger)
          event = dataset_import_created_event.reload
          event.dataset.name.should == destination_table_name
          event.dataset.schema.should == sandbox
        end
      end

      context "when dataset refresh fails" do
        before do
          any_instance_of(Schema) do |schema|
            stub(schema).refresh_datasets.with_any_args do
              raise ActiveRecord::JDBCError, "refresh failed -- oh no!"
            end
          end
        end

        it "still creates a DatasetImportSuccess event with an empty dataset link" do
          expect {
            expect {
              send(trigger)
            }.not_to raise_error
          }.to change(Events::DatasetImportSuccess, :count).by(1)
          event = Events::DatasetImportSuccess.last
          event.dataset.should be_nil
        end
      end

      context "when new table cannot be found" do
        before do
          any_instance_of(Schema) do |schema|
            stub(schema).refresh_datasets.with_any_args { [] }
          end
        end

        it "still creates a DatasetImportSuccess event with an empty dataset link" do
          expect {
            send(trigger)
          }.to change(Events::DatasetImportSuccess, :count).by(1)
          event = Events::DatasetImportSuccess.last
          event.dataset.should be_nil
        end
      end
    end

    context "when the import created event cannot be found" do
      before do
        dataset_import_created_event.delete
      end

      it "doesn't blow up" do
        expect {
          send(trigger)
        }.not_to raise_error
      end
    end
  end

  shared_examples_for :it_fails_with_message do | trigger, message |
    let(:expected_failure_message) { message }

    context "when the import fails" do
       it "creates a DatasetImportFailed" do
        expect {
          send(trigger)
        }.to change(Events::DatasetImportFailed, :count).by(1)

        event = Events::DatasetImportFailed.last
        event.actor.should == user
        event.error_message.should == expected_failure_message
        event.workspace.should == workspace
        event.source_dataset.should == source_dataset
        event.destination_table.should == destination_table_name
      end

      it "creates a notification" do
        expect {
          send(trigger)
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        notification.recipient_id.should == user.id
        notification.event_id.should == Events::DatasetImportFailed.last.id
      end

      it "marks the import as failed" do
        send(trigger)
        import.reload
        import.success.should be_false
        import.finished_at.should_not be_nil
      end

     it_behaves_like :it_generates_no_events_when_already_marked_as_passed_or_failed, trigger
    end
  end

  describe ".run" do
    context "when the import has already been run" do
      before do
        import.success = true
        import.save!
      end

      it "skips the import" do
        any_instance_of ImportExecutor do |executor|
          mock(executor).run.with_any_args.times(0)
        end
        ImportExecutor.run(import.id)
      end
    end
  end

  describe "#run" do
    def mock_import
      mock(GpTableCopier).run_import(database_url, database_url, anything) do | *args |
        raise import_failure_message if import_failure_message.present?
        yield *args if block_given?
      end
    end

    before do
      any_instance_of(Schema) do |schema|
        stub(schema).refresh_datasets.with_any_args do
          FactoryGirl.create(:gpdb_table, :name => destination_table_name, :schema => sandbox)
        end
      end
    end

    let(:run_import) do
      mock_import
      ImportExecutor.new(import).run
    end

    it "creates a new table copier and runs it" do
      run_import
    end

    it "sets the started_at time" do
      expect {
        run_import
      }.to change(import, :started_at).from(nil)
      import.started_at.should be_within(1.hour).of(Time.current)
    end

    it "passes the import id and created_at time as the pipe_name attribute to GpTableCopier.run_import" do
      mock_import do | src_url, dst_url, attributes |
        attributes[:pipe_name].should == "#{import.created_at.to_i}_#{import.id}"
      end
      ImportExecutor.run(import.id)
    end

    context "when the import succeeds" do
      it_behaves_like :it_succeeds, :run_import
    end

    context "when the import fails" do
      let(:import_failure_message) { "some crazy error" }
      let(:run_failing_import) do
        expect {
          run_import
        }.to raise_error import_failure_message
      end

      it_behaves_like :it_fails_with_message, :run_failing_import, "some crazy error"
    end

    context "where the import source dataset has been deleted" do
      before do
        source_dataset.destroy
        import.reload # reload the deleted source dataset
      end

      let(:error_message) { "Original source dataset #{source_dataset.scoped_name} has been deleted" }
      let(:run_import) {
        ImportExecutor.new(import).run
      }

      it "raises an error" do
        expect {
          run_import
        }.to raise_error error_message
      end

      it "creates a DatasetImportFailed" do
        expect {
          expect {
            run_import
          }.to raise_error error_message
        }.to change(Events::DatasetImportFailed, :count).by(1)

        event = Events::DatasetImportFailed.last
        event.error_message.should == error_message
      end
    end

    context "where the workspace has been deleted" do
      let(:error_message) { "Destination workspace #{workspace.name} has been deleted" }

      before do
        workspace.destroy
        import.reload # reload the deleted source dataset
      end

      let(:run_import) {
        ImportExecutor.new(import).run
      }

      it "raises an error" do
        expect {
          run_import
        }.to raise_error error_message
      end

      it "creates a DatasetImportFailed" do
        expect {
          expect {
            run_import
          }.to raise_error error_message
        }.to change(Events::DatasetImportFailed, :count).by(1)

        event = Events::DatasetImportFailed.last
        event.error_message.should == error_message
        event.workspace.should == workspace
      end
    end
  end

  describe ".cancel" do
    before do
      mock(ImportTerminator).terminate(import)
      any_instance_of(Schema) do |schema|
        stub(schema).refresh_datasets.with_any_args do
          FactoryGirl.create(:gpdb_table, :name => destination_table_name, :schema => sandbox)
        end
      end
    end

    describe "when the import is marked as successful" do
      let(:cancel_import) do
        ImportExecutor.cancel(import, true)
      end

      it_behaves_like :it_succeeds, :cancel_import
    end

    describe "when the import is marked as failed with a message" do
      let(:cancel_import) do
        ImportExecutor.cancel(import, false, "some crazy error")
      end

      it_behaves_like :it_fails_with_message, :cancel_import, "some crazy error"
    end
  end
end
