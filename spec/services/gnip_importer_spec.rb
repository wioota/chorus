require 'spec_helper'

describe GnipImporter do
  let(:gnip_import_created_event) { events(:gnip_stream_import_created) }

  describe "#import_to_table" do
    let(:user) { users(:owner) }
    let(:gnip_csv_result_mock) { GnipCsvResult.new("a,b,c\n1,2,3") }
    let(:gnip_instance) { gnip_instances(:default) }
    let(:workspace) { workspaces(:public) }
    let(:resource_urls) { ["url1"] }
    let(:raise_error_message) { "" }

    before do
      mock(ChorusGnip).from_stream(gnip_instance.stream_url,
                                   gnip_instance.username,
                                   gnip_instance.password) do |c|
        raise raise_error_message unless raise_error_message.blank?
        stub(c).to_result_in_batches(is_a(Array)) {
          gnip_csv_result_mock
        }
        mock(c).fetch { resource_urls }
      end

      stub_gpdb(workspace.sandbox.gpdb_instance.owner_account,
                "DROP TABLE IF EXISTS foobar" => lambda {
                  throw :dropped_table if @throw_on_dropped_table
                  []
                })
      stub(Dataset).refresh(anything, workspace.sandbox) do
        FactoryGirl.create(:gpdb_table, :name => "foobar", :schema => workspace.sandbox)
      end
    end

    def do_import
      GnipImporter.import_to_table('foobar', gnip_instance.id,
                                   workspace.id, user.id, gnip_import_created_event.id)
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
        event.actor.should == gnip_import_created_event.actor

        gnip_import_created_event.reload.dataset.should_not be_nil

        event.dataset.should == gnip_import_created_event.dataset
        event.workspace.should == gnip_import_created_event.workspace
      end

      it "creates notification for actor on import success" do
        expect {
          do_import
        }.to change(Notification, :count).by(1)
        notification = Notification.last
        notification.recipient_id.should == gnip_import_created_event.actor.id
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
        event.actor.should == gnip_import_created_event.actor
        event.destination_table.should == 'foobar'
        event.error_message.should == raise_error_message
        event.workspace.should == gnip_import_created_event.workspace
      end

      it "creates notification for actor on import failure" do
        expect {
          expect {
            do_import
          }.to raise_error("mock exception from test")
        }.to change(Notification, :count).by(1)
        notification = Notification.last
        notification.recipient_id.should == gnip_import_created_event.actor.id
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
        @throw_on_dropped_table = true
        expect {
          do_import
        }.to throw_symbol(:dropped_table)
      end
    end

    context "when there is no max file size configuration" do
      before do
        stub(Chorus::Application.config).[]("gnip.csv_import_max_file_size_mb") { nil }
        any_instance_of (CsvFile) do |file|
          stub(file).contents_file_size { 51 }
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
        stub(Chorus::Application.config).[]("gnip.csv_import_max_file_size_mb") { 70 }
        any_instance_of (CsvFile) do |file|
          stub(file).contents_file_size { 60 }
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