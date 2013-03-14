shared_examples_for :import_generates_no_events do |trigger|
  it "generates no new events or notifications" do
    expect {
      expect {
        send(trigger)
      }.not_to change(Events::Base, :count)
    }.not_to change(Notification, :count)
  end
end

shared_examples_for :import_generates_no_events_when_already_marked_as_passed_or_failed do |trigger|
  context "when the import is already marked as passed" do
    before do
      import.success = true
      import.save!
    end
    it_behaves_like :import_generates_no_events, trigger
  end

  context "when the import is already marked as failed" do
    before do
      import.success = false
      import.save!
    end
    it_behaves_like :import_generates_no_events, trigger
  end
end

shared_examples_for :import_succeeds do |trigger|
  context "when import is successful" do
    it "creates a success event and notification" do
      mock(import).create_passed_event_and_notification
      send(trigger)
    end

    it "marks the import as success" do
      send(trigger)
      import.reload
      import.success.should be_true
      import.finished_at.should_not be_nil
    end

    it "refreshes the schema" do
      mock(sandbox).refresh_datasets(sandbox.database.data_source.account_for_user!(user))
      send(trigger)
    end

    it "updates the destination dataset id" do
      send(trigger)
      import.reload
      import.success.should be_true
      import.destination_dataset_id.should_not be_nil
    end

    it "sets the dataset attribute of the DATASET_IMPORT_CREATED event" do
      send(trigger)
      event = import_created_event.reload
      event.dataset.name.should == destination_table_name
      event.dataset.schema.should == sandbox
    end

    it_behaves_like :import_generates_no_events_when_already_marked_as_passed_or_failed, trigger

    context "when the import is a scheduled import" do
      let(:import_schedule_id) { 1234 }

      before do
        import_created_event.reference_id = import_schedule_id
        import_created_event.reference_type = ImportSchedule.name
        import_created_event.save!
        import.import_schedule_id = import_schedule_id
        import.save!
      end

      it "still sets the dataset attribute of the DATASET_IMPORT_CREATED event" do
        send(trigger)
        event = import_created_event.reload
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
          stub.proxy(schema).datasets do |datasets_relation|
            stub.proxy(datasets_relation).tables do |tables_relation|
              stub(tables_relation).find_by_name(destination_table_name) { nil }
            end
          end
        end
      end

      it "still creates a destinationImportSuccess event with an empty dataset link" do
        expect {
          expect {
            send(trigger)
          }.not_to raise_error
        }.to change(Events::WorkspaceImportSuccess, :count).by(1)
        event = Events::WorkspaceImportSuccess.last
        event.dataset.should be_nil
      end
    end
  end

  context "when the import created event cannot be found" do
    before do
      import_created_event.delete
    end

    it "doesn't blow up" do
      expect {
        send(trigger)
      }.not_to raise_error
    end
  end
end

shared_examples_for :import_fails_with_message do |trigger, message|
  let(:expected_failure_message) { message }

  context "when the import fails" do
    it "creates " do
      mock(import).create_failed_event_and_notification(message)
      send(trigger)
    end

    it "marks the import as failed" do
      send(trigger)
      import.reload
      import.success.should be_false
      import.finished_at.should_not be_nil
    end

    it_behaves_like :import_generates_no_events_when_already_marked_as_passed_or_failed, trigger
  end
end
