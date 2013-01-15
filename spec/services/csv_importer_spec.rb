require 'tempfile'
require 'spec_helper'

describe CsvImporter do
  let(:csv_file) { create_csv_file }
  let(:table_name) { "another_new_table_from_csv" }
  let(:user) { csv_file.user }
  let(:file_import_created_event) { Events::FileImportCreated.last }
  let(:destination_dataset) { FactoryGirl.build :gpdb_table, :name => csv_file.to_table }

  describe "with a real database connection", :database_integration => true do
    let(:database) { GpdbDatabase.find_by_name_and_gpdb_instance_id(InstanceIntegration.database_name, InstanceIntegration.real_gpdb_instance)}
    let(:schema) { database.schemas.find_by_name('test_schema') }
    let(:user) { account.owner }
    let(:account) { InstanceIntegration.real_gpdb_account }
    let(:workspace) { FactoryGirl.create(:workspace, :sandbox => schema, :owner => user, :name => "test_csv_workspace") }
    let(:error_on_import) { false }

    before do
      any_instance_of(CsvImporter) do |importer|
        stub(importer).destination_dataset { destination_dataset }
      end
    end

    after do
      schema.connect_with(account).drop_table(table_name)
    end

    describe ".import_file" do
      before do
        any_instance_of(CsvImporter) do |importer|
          mock(importer).import_with_events do
            raise "import failed!" if error_on_import
          end
        end
      end

      subject do
        CsvImporter.import_file(csv_file.id, file_import_created_event.id)
      end

      it "creates an import" do
        mock.proxy(CsvImporter).new(csv_file.id, file_import_created_event.id)
        subject
      end

      it "executes import_with_events" do
        subject
      end

      it "deletes the csv file" do
        subject
        CsvFile.find_by_id(csv_file.id).should be_nil
      end

      context "when the import fails" do
        let(:error_on_import) {true}
        it "still deletes the csv file" do
          expect {
            subject
          }.to raise_error "import failed!"
          CsvFile.find_by_id(csv_file.id).should be_nil
        end
      end
    end

    describe "#import" do
      let(:csv_importer) { CsvImporter.new(csv_file.id, file_import_created_event.id) }

      it "imports the data" do
        csv_importer.import
      end
    end

    describe "#import_with_events" do
      context "when the target table does not exist" do
        it "creates a new table with data from the csv file" do
          CsvImporter.import_file(csv_file.id, file_import_created_event.id)

          result = schema.connect_with(account).fetch(<<-SQL)
            SELECT *
            FROM #{table_name}
            ORDER BY id ASC;
          SQL

          result[0].should == {:id => 1, :where => "foo"}
          result[1].should == {:id => 2, :where => "bar"}
          result[2].should == {:id => 3, :where => "baz"}
        end
      end

      context "when the target table does exist" do
        it "appends data from the csv file to that table" do
          2.times do |iteration|
            csv_file = create_csv_file(:new_table => (iteration == 0))
            CsvImporter.import_file(csv_file.id, file_import_created_event.id)

            fetch_from_gpdb("select count(*) from #{table_name};") do |result|
              result[0]["count"].should == 3 * (iteration + 1)
            end
          end
        end
      end

      it "persists an Import record with the details of the import" do
        Timecop.freeze(Time.current) do
          expect {
            CsvImporter.import_file(csv_file.id, file_import_created_event.id)
          }.to change(Import, :count).by(1)

          import = Import.last
          import.file_name.should == csv_file.contents_file_name
          import.workspace_id.should == csv_file.workspace_id
          import.to_table.should == csv_file.to_table
          import.success.should be_true
          import.finished_at.should == Time.current
        end
      end

      context "when the csv file is not completely populated" do
        it "refuses to import a csv file" do
          csv_file.update_attribute(:delimiter, nil)
          expect do
            expect {
              CsvImporter.import_file(csv_file.id, file_import_created_event.id)
            }.to raise_error
          end.to change(Events::FileImportFailed, :count).by 1
          Events::FileImportFailed.last.error_message.should == 'CSV file cannot be imported'
        end
      end

      context "when truncation is enabled for the import" do
        it "should truncate the existing table" do
          existing_csv_file = create_csv_file(:new_table => true)
          CsvImporter.import_file(existing_csv_file.id, file_import_created_event.id)

          csv_file = create_csv_file(:new_table => false,
                                     :truncate => true,
                                     :contents => tempfile_with_contents("1,larry\n2,barry\n"))
          CsvImporter.import_file(csv_file.id, file_import_created_event.id)

          fetch_from_gpdb("select * from #{table_name} order by id asc;") do |result|
            result[0]["where"].should == "larry"
            result[1]["where"].should == "barry"
            result.count.should == 2
          end
        end
      end

      context "when the column order is different between the csv file and the existing table" do
        it "imports the data, matching existing column names" do
          first_csv_file = create_csv_file(:contents => tempfile_with_contents("1,foo\n2,bar\n3,baz\n"),
                                 :column_names => [:id, :name],
                                 :types => [:integer, :varchar])

          CsvImporter.import_file(first_csv_file.id, file_import_created_event.id)

          second_csv_file = create_csv_file(:contents => tempfile_with_contents("dig,4\ndug,5\ndag,6\n"),
                                 :column_names => [:name, :id],
                                 :types => [:varchar, :integer],
                                 :new_table => false)

          CsvImporter.import_file(second_csv_file.id, file_import_created_event.id)

          fetch_from_gpdb("select * from #{table_name} order by id asc;") do |result|
            result[0]["id"].should == 1
            result[0]["name"].should == "foo"
            result[1]["id"].should == 2
            result[1]["name"].should == "bar"
            result[2]["id"].should == 3
            result[2]["name"].should == "baz"
            result[3]["id"].should == 4
            result[3]["name"].should == "dig"
            result[4]["id"].should == 5
            result[4]["name"].should == "dug"
            result[5]["id"].should == 6
            result[5]["name"].should == "dag"
          end
        end
      end

      context "when the csv file has fewer columns than the destination table" do
        it "sets the extra columns to nil" do
          first_csv_file = create_csv_file(
              :contents => tempfile_with_contents("1,a,snickers\n2,b,kitkat\n"),
              :column_names => [:id, :name, :candy_type],
              :types => [:integer, :varchar, :varchar])

          CsvImporter.import_file(first_csv_file.id, file_import_created_event.id)

          second_csv_file = create_csv_file(
              :contents => tempfile_with_contents("marsbar,3\nhersheys,4\n"),
              :column_names => [:candy_type, :id],
              :types => [:varchar, :integer],
              :new_table => false)

          CsvImporter.import_file(second_csv_file.id, file_import_created_event.id)

          fetch_from_gpdb("select * from #{table_name} order by id asc;") do |result|
            result[0]["id"].should == 1
            result[0]["name"].should == "a"
            result[0]["candy_type"].should == "snickers"
            result[1]["id"].should == 2
            result[1]["name"].should == "b"
            result[1]["candy_type"].should == "kitkat"
            result[2]["id"].should == 3
            result[2]["name"].should == nil
            result[2]["candy_type"].should == "marsbar"
            result[3]["id"].should == 4
            result[3]["name"].should == nil
            result[3]["candy_type"].should == "hersheys"
          end
        end
      end

      context "when the csv file has different column names, header rows and a different delimiter" do
        it "loads the data but ignores the extra columns" do
          csv_file = create_csv_file(
              :contents => tempfile_with_contents("ignore\tme\n1\tfoo\n2\tbar\n3\tbaz\n"),
              :column_names => [:id, :dog],
              :types => [:integer, :varchar],
              :delimiter => "\t",
              :file_contains_header => true)
          CsvImporter.import_file(csv_file.id, file_import_created_event.id)

          fetch_from_gpdb("select * from #{table_name} order by ID asc;") do |result|
            result[0].should == {"id" => 1, "dog" => "foo"}
            result[1].should == {"id" => 2, "dog" => "bar"}
            result[2].should == {"id" => 3, "dog" => "baz"}
          end
        end
      end

      context "when import fails" do
        let(:csv_file) do
          create_csv_file(
              :contents => tempfile_with_contents("1,hi,three"),
              :column_names => [:id, :name],
              :types => [:integer, :varchar])
        end

        it "sets the import record success to false" do
          Timecop.freeze(Time.current) do
            any_instance_of(CsvFile) do |file|
              stub(file).ready_to_import? { false }
            end
            expect {
              CsvImporter.import_file(csv_file.id, file_import_created_event.id)
            }.to raise_error("CSV file cannot be imported")
            Import.last.success.should be_false
            Import.last.finished_at.should == Time.current
          end
        end

        it "removes import table when new_table is true" do
          any_instance_of(CsvImporter) { |importer|
            stub(importer).check_if_table_exists.with_any_args { false }
          }
          expect {
            CsvImporter.import_file(csv_file.id, file_import_created_event.id)
          }.to raise_error(CsvImporter::ImportFailed)


          expect {
            schema.connect_with(account).fetch("SELECT * FROM #{table_name}")
          }.to raise_error(GreenplumConnection::DatabaseError)
        end

        it "does not remove import table when new_table is false" do
          first_csv_file = create_csv_file(
              :contents => tempfile_with_contents("1,hi"),
              :column_names => [:id, :name],
              :types => [:integer, :varchar])

          CsvImporter.import_file(first_csv_file.id, file_import_created_event.id)

          second_csv_file = create_csv_file(
              :contents => tempfile_with_contents("1,hi,three"),
              :column_names => [:id, :name],
              :types => [:integer, :varchar],
              :new_table => false)

          expect {
            CsvImporter.import_file(second_csv_file.id, file_import_created_event.id)
          }.to raise_error

          expect {
            schema.connect_with(account).fetch("SELECT * FROM #{table_name}")
          }.not_to raise_error

        end

        it "does not remove the table if new_table is true, but the table already existed" do
          any_instance_of(CsvImporter) { |importer|
            stub(importer).check_if_table_exists.with_any_args { true }
          }

          expect {
            CsvImporter.import_file(csv_file.id, file_import_created_event.id)
          }.to raise_error(CsvImporter::ImportFailed)

          expect {
            schema.connect_with(account).fetch("SELECT * FROM #{table_name}")
          }.not_to raise_error
        end
      end

      def fetch_from_gpdb(sql)
        schema.connect_with(account).fetch(sql)
      end
    end
  end

  describe "without connecting to GPDB" do
    let(:csv_file) do
      file = CsvFile.first
      file.update_attributes :new_table => false
      file
    end
    let(:instance_account) { csv_file.workspace.sandbox.gpdb_instance.account_for_user!(csv_file.user) }

    describe "after creating the csv file" do
      it "performs a refresh and returns the dataset matching the import table name" do
        mock(Dataset).refresh(instance_account, csv_file.workspace.sandbox)
        importer = CsvImporter.new(csv_file.id,  file_import_created_event.id)
        importer.destination_dataset.name.should == csv_file.to_table
      end
    end

    describe "when the import is successful" do
      before do
        # skip database connection
        any_instance_of(GpdbSchema) { |schema| stub(schema).with_gpdb_connection }

        # fake out dataset refresh and search for new dataset
        any_instance_of(CsvImporter) do |importer|
          stub(importer).destination_dataset { destination_dataset }
        end
      end

      subject do
        CsvImporter.import_file(csv_file.id, file_import_created_event.id)
      end

      it "makes a IMPORT_SUCCESS event" do
        expect {
          subject
        }.to change(Events::FileImportSuccess, :count).by(1)
        event = Events::FileImportSuccess.last
        event.actor.should == user
        event.dataset.should == destination_dataset
        event.workspace.should == csv_file.workspace
        event.file_name.should == csv_file.contents_file_name
        event.import_type.should == 'file'
      end

      it "makes sure the FileImportSuccess event object is linked to the dataset" do
        subject
        file_import_created_event.reload
        file_import_created_event.dataset.should == destination_dataset
        file_import_created_event.target2_type.should == "Dataset"
        file_import_created_event.target2_id.should == destination_dataset.id
      end

      it "deletes the file" do
        subject
        CsvFile.find_by_id(csv_file.id).should be_nil
      end

      it "generates notification to import actor" do
        subject
        notification = Notification.last
        notification.recipient_id.should == user.id
        notification.event_id.should == Events::FileImportSuccess.last.id
      end
    end

    describe "when trying to make an invalid import" do
      let(:csv_file) do
        file = CsvFile.first
        file.update_attributes :new_table => true
        file
      end

      it "does not crash" do
        expect {
          CsvImporter.import_file(csv_file.id, file_import_created_event.id)
        }.to raise_exception
      end
    end

    describe "when the import fails" do
      before do
        @error = 'ActiveRecord::JDBCError: ERROR: relation "test" already exists: CREATE TABLE test(a float, b float, c float);'
        exception = ActiveRecord::StatementInvalid.new(@error)
        any_instance_of(GpdbSchema) { |schema| stub(schema).with_gpdb_connection { raise exception } }
        any_instance_of(CsvImporter) do |importer|
          stub(importer).destination_dataset { destination_dataset }
        end
      end

      subject do
        expect {
          CsvImporter.import_file(csv_file.id, file_import_created_event.id)
        }.to raise_error(CsvImporter::ImportFailed)
      end

      it "makes a IMPORT_FAILED event" do
        expect {
          subject
        }.to change(Events::FileImportFailed, :count).by(1)
        event = Events::FileImportFailed.last
        event.actor.should == user
        event.destination_table.should == destination_dataset.name
        event.workspace.should == csv_file.workspace
        event.dataset.should == destination_dataset
        event.file_name.should == csv_file.contents_file_name
        event.import_type.should == 'file'
        event.error_message.should == @error
      end

      it "deletes the file" do
        subject
        CsvFile.find_by_id(csv_file.id).should be_nil
      end

      it "generates notification to import actor" do
        subject
        notification = Notification.last
        notification.recipient_id.should == user.id
        notification.event_id.should == Events::FileImportFailed.last.id
      end
    end
  end

  def create_csv_file(options = {})
    defaults = {
        :contents => tempfile_with_contents("1,foo\n2,bar\n3,baz\n"),
        :column_names => [:id, :where],
        :types => [:integer, :varchar],
        :delimiter => ',',
        :file_contains_header => false,
        :new_table => true,
        :to_table => table_name,
        :truncate => false
    }
    CsvFile.create(defaults.merge(options)) do |csv_file|
      csv_file.user = user
      csv_file.workspace = workspace
    end
  end

  def tempfile_with_contents(str)
    f = Tempfile.open("test_csv")
    f.puts str
    f.close
    f
  end
end