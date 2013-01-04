require 'spec_helper'

describe GnipImporter do
  let(:user) { users(:owner) }
  let(:workspace) { workspaces(:public) }
  let(:instance) { gnip_instances(:default) }
  let(:import_created_event) { events(:gnip_stream_import_created) }
  let(:connection) { Object.new }

  before do
    # We need to stub the find method as unfortunately without this it doesn't
    # return an object with our mocks on.
    stub(Workspace).find(workspace.id) { workspace }
    stub(workspace.sandbox).connect_with(anything) { connection }
    stub(connection).drop_table(anything)
  end

  describe "validations", :database_integration do
    let(:workspace) { workspaces(:real) }
    let(:schema) { workspace.sandbox }
    let(:instance) { schema.gpdb_instance }
    let(:user) { instance.owner }

    context "when table name already exists" do
      let(:table_name) { schema.active_tables_and_views.first.name }

      it "adds an error on table_name" do
        importer = GnipImporter.new(table_name, instance.id, workspace.id, user.id, import_created_event.id)
        importer.should_not be_valid
        importer.should have_error_on(:table_name).with_message(:table_exists).with_options(:table_name => table_name)
      end
    end

    context "when schema does not exist" do
      before do
        schema.update_attribute(:name, 'something_fake')
      end

      it "adds an error on table_name" do
        importer = GnipImporter.new('table_name', instance.id, workspace.id, user.id, import_created_event.id)
        importer.should_not be_valid
        importer.should have_error_on(:workspace).with_message(:missing_sandbox)
      end
    end

    context "when workspace doesn't have a sandbox" do
      let!(:instance) { schema.gpdb_instance }
      before do
        workspace.sandbox = nil
        workspace.save!
      end

      it "adds an error on workspace" do
        importer = GnipImporter.new('table_name', instance.id, workspace.id, user.id, import_created_event.id)
        importer.should_not be_valid
        importer.should have_error_on(:workspace).with_message(:empty_sandbox)
      end
    end

    describe "validate!" do
      it "raises ApiValidationError when the model is not valid" do
        importer = GnipImporter.new('table_name', instance.id, workspace.id, user.id, import_created_event.id)
        stub(importer).valid? { false }
        expect { importer.validate! }.to raise_error(ApiValidationError)
      end
    end
  end

  describe "#import_to_table" do
    let(:gnip_csv_result_mock) { GnipCsvResult.new("a,b,c\n1,2,3") }
    let(:resource_urls) { ["url1"] }
    let(:raise_error_message) { "" }

    before do
      mock(ChorusGnip).from_stream(instance.stream_url, instance.username, instance.password) do |c|
        raise raise_error_message unless raise_error_message.blank?
        stub(c).to_result_in_batches(is_a(Array)) {
          gnip_csv_result_mock
        }
        mock(c).fetch { resource_urls }
      end

      stub(Dataset).refresh(anything, workspace.sandbox) do
        FactoryGirl.create(:gpdb_table, :name => "foobar", :schema => workspace.sandbox)
      end
    end

    def do_import
      GnipImporter.import_to_table('foobar', instance.id,
                                   workspace.id, user.id, import_created_event.id)
    end

    context "when the gnip stream is split into multiple csv files" do
      let(:resource_urls) { ['url_1', 'url_2'] }

      before do
        any_instance_of(CsvImporter) do |importer|
          stub(importer).import { @imports_remaining -= 1 }
        end

        @imports_remaining = resource_urls.length
      end

      it "iterates through each url and passes it to import_file" do
        do_import
        @imports_remaining.should == 0
      end

      it "leaves no csv files in the database" do
        expect {
          do_import
        }.to change(CsvFile, :count).by(0)
      end

      it "generates a single success event with the correct attributes" do
        expect {
          do_import
        }.to change(Events::GnipStreamImportSuccess, :count).by(1)

        event = Events::GnipStreamImportSuccess.last
        event.actor.should == import_created_event.actor

        import_created_event.reload.dataset.should_not be_nil

        event.dataset.should == import_created_event.dataset
        event.workspace.should == import_created_event.workspace
      end

      it "creates notification for actor on import success" do
        expect {
          do_import
        }.to change(Notification, :count).by(1)
        notification = Notification.last
        notification.recipient_id.should == import_created_event.actor.id
        notification.event_id.should == Events::GnipStreamImportSuccess.last.id
      end
    end

    context "when the list of urls is empty" do
      let(:resource_urls) { [] }

      it "does not generate an error" do
        expect {
          do_import
        }.to_not raise_error
      end
    end

    context "when the list of urls contains an error message" do
      let(:resource_urls) { "{\"status\":\"error\",\"reason\":\"Data file not found, please contact support@gnip.com regarding snapshot job: xxxxxxx\"}" }

      it "raises a GnipException with the message" do
        expect {
          do_import
        }.to raise_error(GnipException, "Data file not found, please contact support@gnip.com regarding snapshot job: xxxxxxx")
      end
    end

    context "when ChorusGnip or something else raises an exception" do
      let(:raise_error_message) { "mock exception from test" }

      it "creates a import failed event with the correct attributes" do
        expect {
          expect {
            do_import
          }.to raise_error("mock exception from test")
        }.to change(Events::GnipStreamImportFailed, :count).by(1)
        event = Events::GnipStreamImportFailed.last
        event.actor.should == import_created_event.actor
        event.destination_table.should == 'foobar'
        event.error_message.should == raise_error_message
        event.workspace.should == import_created_event.workspace
      end

      it "creates notification for actor on import failure" do
        expect {
          expect {
            do_import
          }.to raise_error("mock exception from test")
        }.to change(Notification, :count).by(1)
        notification = Notification.last
        notification.recipient_id.should == import_created_event.actor.id
        notification.event_id.should == Events::GnipStreamImportFailed.last.id
      end
    end

    context "when importing an individual csv file to the table fails" do
      before do
        any_instance_of(CsvImporter) do |csv_importer|
          mock(csv_importer).import do
            raise "csv import failed"
          end
        end
      end

      it "leaves no csv files in the database" do
        expect {
          expect {
            do_import
          }.to raise_error "csv import failed"
        }.to change(CsvFile, :count).by(0)
      end

      it "drops the new table" do
        stub(connection).drop_table(anything) { throw :dropped_table }

        expect {
          do_import
        }.to throw_symbol(:dropped_table)
      end
    end

    context "when there is no max file size configuration" do
      before do
        stub(Chorus::Application.config).[]("gnip.csv_import_max_file_size_mb") { nil }
        any_instance_of (CsvFile) do |file|
          stub(file).contents_file_size { 51.megabytes }
        end
      end

      it "fails if the file is larger than 50mb" do
        expect {
          do_import
        }.to raise_error(GnipFileSizeExceeded)
      end
    end

    context "when individual chunk size exceeds the max file size allowed" do
      before do
        stub(Chorus::Application.config).[]("gnip.csv_import_max_file_size_mb") { 50.megabytes }
        any_instance_of (CsvFile) do |file|
          stub(file).contents_file_size { 60.megabytes }
        end
      end

      it "creates a failed event with a helpful message" do
        expect {
          expect {
            do_import
          }.to raise_error(GnipFileSizeExceeded, "Gnip download chunk exceeds maximum allowed file size for Gnip imports.  Consider increasing the system limit.")
        }.to change(Events::GnipStreamImportFailed, :count).by(1)
      end

      it "creates a notification" do
        expect {
          expect {
            do_import
          }.to raise_error(GnipFileSizeExceeded)
        }.to change(Notification, :count).by(1)
      end
    end
  end
end
