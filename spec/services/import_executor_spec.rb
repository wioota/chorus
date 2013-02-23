require 'spec_helper'
require 'fakefs/spec_helpers'

describe ImportExecutor do
  let(:user) { users(:owner) }
  let(:source_dataset) { datasets(:table) }
  let(:workspace) { workspaces(:public) }
  let(:sandbox) { workspace.sandbox }
  let(:destination_table_name) { "dst_table" }
  let(:database_url) { sandbox.database.connect_with(account).db_url }
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
                      :source_dataset => source_dataset).tap { |i| i.save(:validate => false) }
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

  shared_examples_for :it_succeeds do |trigger|
    context "when import is successful" do
      it "creates a DatasetImportSuccess" do
        expect {
          send(trigger)
        }.to change(Events::DatasetImportSuccess, :count).by(1)

        event = Events::DatasetImportSuccess.last

        event.actor.should == user
        event.workspace.should == workspace
        event.source_dataset.should == source_dataset
      end

      it "creates a DatasetImportSucess with the correct dataset" do
        # Make sure event doesn't reference rogue ChorusView with the same name
        FactoryGirl.create(:chorus_view,
                           :name => destination_table_name,
                           :schema => sandbox,
                           :workspace => workspace)

        expect {
          send(trigger)
        }.to change(Dataset, :count).by(1)

        dataset = Dataset.last

        event = Events::DatasetImportSuccess.last
        event.dataset.name.should == destination_table_name
        event.dataset.schema.should == sandbox
        event.dataset.id.should == dataset.id
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

  shared_examples_for :it_fails_with_message do |trigger, message|
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
    def mock_copier
      mock(TableCopier).new(anything) do |*args|
        raise import_failure_message if import_failure_message.present?
        yield *args if block_given?
        Object.new.tap { |o| stub(o).start }
      end
    end

    before do
      any_instance_of(Schema) do |schema|
        stub(schema).refresh_datasets.with_any_args do
          FactoryGirl.create(:gpdb_table, :name => destination_table_name, :schema => sandbox)
        end
      end
    end

    let(:copier_start) do
      mock_copier
      ImportExecutor.new(import).run
    end

    it "creates a new table copier and runs it" do
      copier_start
    end

    it "sets the started_at time" do
      expect {
        copier_start
      }.to change(import, :started_at).from(nil)
      import.started_at.should be_within(1.hour).of(Time.current)
    end

    it "Uses the import id and created_at time in the pipe_name" do
      mock_copier do |attributes|
        attributes[:pipe_name].should == "#{import.created_at.to_i}_#{import.id}"
      end
      ImportExecutor.run(import.id)
    end

    context "when the import succeeds" do
      it_behaves_like :it_succeeds, :copier_start
    end

    context "when the import fails" do
      let(:import_failure_message) { "some crazy error" }
      let(:run_failing_import) do
        expect {
          copier_start
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
      let(:copier_start) {
        ImportExecutor.new(import).run
      }

      it "raises an error" do
        expect {
          copier_start
        }.to raise_error error_message
      end

      it "creates a DatasetImportFailed" do
        expect {
          expect {
            copier_start
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

      let(:copier_start) {
        ImportExecutor.new(import).run
      }

      it "raises an error" do
        expect {
          copier_start
        }.to raise_error error_message
      end

      it "creates a DatasetImportFailed" do
        expect {
          expect {
            copier_start
          }.to raise_error error_message
        }.to change(Events::DatasetImportFailed, :count).by(1)

        event = Events::DatasetImportFailed.last
        event.error_message.should == error_message
        event.workspace.should == workspace
      end
    end

    context "when the source and destinations are in different greenplum databases" do
      let(:source_dataset) { datasets(:searchquery_table) }

      it "should create a CrossDatabaseTableCopier to run the import" do
        dont_allow(TableCopier).new.with_any_args
        ran = false
        any_instance_of(CrossDatabaseTableCopier) do |copier|
          stub(copier).start { ran = true }
        end
        ImportExecutor.new(import).run
        ran.should be_true
      end
    end

    context "when the source dataset is in oracle" do
      let(:source_dataset) { datasets(:oracle_table) }

      it "should create an OracleTableCopier to run the import" do
        dont_allow(TableCopier).new.with_any_args
        ran = false
        any_instance_of(OracleTableCopier) do |copier|
          stub(copier).start { ran = true }
        end
        ImportExecutor.new(import).run
        ran.should be_true
      end
    end

    context "when the table copier requires authorization" do
      let(:source_dataset) { datasets(:oracle_table) }
      let(:copier) { Object.new }
      let(:stream_key) { 'f00baa' }
      let(:stream_url) do
        Rails.application.routes.url_helpers.dataset_ext_stream_url(:dataset_id => source_dataset.id,
                                                                    :row_limit => import.sample_count,
                                                                    :host => ChorusConfig.instance.public_url,
                                                                    :port => ChorusConfig.instance.server_port,
                                                                    :stream_key => stream_key
        )
      end

      let(:copier_params) do
        {
            :source_dataset => source_dataset,
            :stream_url => stream_url
        }
      end

      before do
        stub(copier).start
      end

      it "generates a login key in the import and passes in a stream url to the copier" do
        mock(OracleTableCopier).new(hash_including(copier_params)) { copier }
        stub(import).stream_key { stream_key }
        mock(import).generate_key
        ImportExecutor.new(import).run
      end

      it "erases the stream_key after running" do
        stub(OracleTableCopier).new.with_any_args { copier }
        ImportExecutor.new(import).run
        import.reload.stream_key.should be_nil
      end
    end
  end

  describe ".cancel" do
    let(:source_connection) { Object.new }
    let(:destination_connection) { Object.new }
    let(:executor) { ImportExecutor.new(import) }
    before do
      stub(executor).log.with_any_args
      stub.proxy(executor).source_dataset { |dataset| stub(dataset).connect_as(user) { source_connection } }
      stub.proxy(executor).sandbox { |sandbox| stub(sandbox).connect_as(user) { destination_connection } }
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

    it "should remove the named pipe from disk" do
      dir = ChorusConfig.instance['gpfdist.data_dir']
      FileUtils.mkdir_p dir
      pipe_file = File.join(dir, "pipe_with_some_extra_stuff_#{import.created_at.to_i}_#{import.id}")
      FileUtils.touch pipe_file
      executor.cancel(true)
      File.exists?(pipe_file).should be_false
    end

    describe "when the import is marked as successful" do
      let(:cancel_import) do
        executor.cancel(true)
      end

      it_behaves_like :it_succeeds, :cancel_import
    end

    describe "when the import is marked as failed with a message" do
      let(:cancel_import) do
        executor.cancel(false, "some crazy error")
      end

      it_behaves_like :it_fails_with_message, :cancel_import, "some crazy error"
    end
  end
end
