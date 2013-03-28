require 'spec_helper'

describe Import, :greenplum_integration do
  let(:user)  { schema.data_source.owner }
  let(:workspace) { workspaces(:real) }
  let(:database) { GreenplumIntegration.real_database }
  let(:schema) { database.schemas.find_by_name('test_schema') }
  let(:account) { GreenplumIntegration.real_account }
  let(:gpdb_data_source) { GreenplumIntegration.real_data_source }
  let(:source_dataset) { workspace.sandbox.datasets.find_by_name('candy_one_column') }

  let(:import) do
    WorkspaceImport.create(
        {
            :workspace => workspace,
            :to_table => 'new_table1234',
            :new_table => true,
            :source_dataset => source_dataset,
            :user => user
        }, :without_protection => true)
  end

  before { workspace.update_attribute :sandbox_id, schema.id }

  describe "associations" do
    it { should belong_to(:scoped_source_dataset).class_name('Dataset') }
    it { should belong_to :user }
  end

  describe "validations" do
    let(:import) do
      WorkspaceImport.new.tap do |i|
        i.workspace = workspace
        i.to_table = 'new_table1234'
        i.new_table = true
        i.source_dataset = i.workspace.sandbox.datasets.find_by_name('candy_one_column')
        i.user = user
      end
    end

    it "validates the presence of to_table" do
      import = FactoryGirl.build(:import, :workspace => workspace, :user => user, :to_table => nil)
      import.should_not be_valid
      import.should have_error_on(:to_table)
    end

    it "validates the presence of source_dataset if no file_name present" do
      import = FactoryGirl.build(:import, :workspace => workspace, :user => user, :scoped_source_dataset => nil, :file_name => nil)
      import.should_not be_valid
      import.should have_error_on(:scoped_source_dataset)
      import.should have_error_on(:file_name)
    end

    it "does not validate the presence of source_dataset if file_name present" do
      import = FactoryGirl.build(:import, :workspace => workspace, :user => user, :source_dataset => nil, :file_name => "foo.csv")
      import.should be_valid
    end

    it "validates the presence of user" do
      import = FactoryGirl.build(:import, :workspace => workspace, :user => nil)
      import.should_not be_valid
      import.should have_error_on(:user)
    end

    it "validates that the to_table does not exist already if it is a new table" do
      import.to_table = "master_table1"
      import.should_not be_valid
      import.should have_error_on(:base).with_message(:table_exists)
    end

    it "is valid if an old import's to_table exists" do
      import.to_table = 'second_candy_one_column'
      import.save(:validate => false)
      import.reload
      import.should be_valid
    end

    it "validates that the source and destination have consistent schemas" do
      any_instance_of GpdbDataset do |dataset|
        stub(dataset).can_import_from(anything) { false }
      end
      import.to_table = 'pg_all_types'
      import.new_table = false
      import.should_not be_valid

      import.should have_error_on(:base, :table_not_consistent)
    end

    it "sets the destination_dataset before validation" do
      any_instance_of GpdbDataset do |dataset|
        stub(dataset).can_import_from(anything) { true }
      end
      import.to_table = 'master_table1'
      import.new_table = false
      import.should be_valid
      import.destination_dataset.should == import.workspace.sandbox.datasets.find_by_name('master_table1')
    end

    it "should change a previously set destination dataset" do
      any_instance_of GpdbDataset do |dataset|
        stub(dataset).can_import_from(anything) { true }
      end
      import.destination_dataset = import.source_dataset
      import.to_table = 'master_table1'
      import.new_table = false
      import.should be_valid
      import.destination_dataset.should == import.workspace.sandbox.datasets.find_by_name('master_table1')
    end

    it "is valid if an imports table become inconsistent after saving" do
      import.save
      any_instance_of GpdbDataset do |dataset|
        stub(dataset).can_import_from(anything) { false }
      end

      import.should be_valid
    end
  end

  describe "generate_key" do
    it "generates a stream_key" do
      import.save
      import.generate_key
      import.reload.stream_key.should_not be_nil
    end
  end

  describe "#handle" do
    before do
      import.created_at = Time.at(123456789)
      import.id = 42
    end

    it "returns the right handle" do
      import.handle.should == "123456789_42"
    end
  end

  describe "#update_status" do
    it "updates finished_at" do
      -> {
        import.update_status(:passed)
      }.should change(import, :finished_at)
    end

    it "removes stream_key" do
      import.stream_key = "foobar"

      -> {
        import.update_status(:passed)
      }.should change(import, :stream_key).to(nil)
    end

    context "when import passed" do
      it "marks the import as success and refreshes its schema" do
        mock(import).mark_as_success
        mock(import).refresh_schema
        import.update_status(:passed)
      end

      it "sets success to true" do
        -> {
          import.update_status(:passed)
        }.should change(import, :success).to(true)
      end
    end

    context "when import failed" do
      it "creates failed event and notification" do
        mock(import).create_failed_event_and_notification("a message")
        import.update_status(:failed, "a message")
      end

      it "sets success to false" do
        -> {
          import.update_status(:failed)
        }.should change(import, :success).to(false)
      end
    end
  end

  describe "#source_dataset" do
    it "returns source_dataset even if it is deleted" do
      import.source_dataset.should == source_dataset
      source_dataset.destroy
      import.reload.source_dataset.should == source_dataset
    end
  end

  describe "#workspace" do
    it "returns workspace even if it is deleted" do
      import.workspace.should == workspace
      workspace.destroy
      import.reload.workspace.should == workspace
    end
  end
end
