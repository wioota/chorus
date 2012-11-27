require 'spec_helper'

describe ImportExecutor do
  let(:user) { users(:owner) }
  let(:source_dataset) { datasets(:table) }
  let(:workspace) { workspaces(:public) }
  let(:sandbox) { workspace.sandbox }
  let(:destination_table_name) { "dst_table" }

  let(:attributes) {
    import.attributes.symbolize_keys.slice(:new_table, :truncate, :sample_count, :to_table, :workspace_id).merge(extra_attributes)
  }

  let(:extra_attributes) {{}}

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

  let(:import) { FactoryGirl.create :import,
                                    :user => user,
                                    :workspace => workspace,
                                    :to_table => destination_table_name,
                                    :source_dataset => source_dataset }
  let(:import_failure_message) { "" }

  describe ".run" do
    let(:run_import) {
      mock(GpTableCopier).run_import(source_dataset.id, user.id, attributes) do
        raise import_failure_message if import_failure_message.present?
      end
      stub(Dataset).refresh.with_any_args do
        FactoryGirl.create(:gpdb_table, :name => destination_table_name, :schema => sandbox)
      end
      ImportExecutor.run(import.id)
    }

    it "creates a new table copier and runs it" do
      run_import
    end

    context "when import is successful" do
      it "creates a DatasetImportSuccess" do
        expect {
          run_import
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
          run_import
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        notification.recipient_id.should == user.id
        notification.event_id.should == Events::DatasetImportSuccess.last.id
      end

      it "marks the import as success" do
        run_import
        import.reload
        import.success.should be_true
        import.finished_at.should_not be_nil
      end

      it "updates the destination dataset id" do
        run_import
        import.reload
        import.success.should be_true
        import.destination_dataset_id.should_not be_nil
      end

      it "sets the dataset attribute of the DATASET_IMPORT_CREATED event" do
        run_import
        event = dataset_import_created_event.reload
        event.dataset.name.should == destination_table_name
        event.dataset.schema.should == sandbox
      end

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
          run_import
          event = dataset_import_created_event.reload
          event.dataset.name.should == destination_table_name
          event.dataset.schema.should == sandbox
        end
      end

      context "when the import created event cannot be found" do
        before do
          dataset_import_created_event.delete
        end

        it "doesn't blow up" do
          expect {
            run_import
          }.not_to raise_error
        end
      end
    end

    context "when the import fails" do
      let(:import_failure_message) { "some crazy error" }
      let(:run_failed_import) {
        expect {
          run_import
        }.to raise_error import_failure_message
      }

      it "creates a DatasetImportFailed" do
        expect {
          run_failed_import
        }.to change(Events::DatasetImportFailed, :count).by(1)

        event = Events::DatasetImportFailed.last
        event.actor.should == user
        event.error_message.should == import_failure_message
        event.workspace.should == workspace
        event.source_dataset.should == source_dataset
        event.destination_table.should == destination_table_name
      end

      it "creates a notification" do
        expect {
          run_failed_import
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        notification.recipient_id.should == user.id
        notification.event_id.should == Events::DatasetImportFailed.last.id
      end

      it "marks the import as failed" do
        run_failed_import
        import.reload
        import.success.should be_false
        import.finished_at.should_not be_nil
      end
    end
  end
end
