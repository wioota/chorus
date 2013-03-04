require 'spec_helper'

describe Import, :greenplum_integration do
  let(:user)  { schema.data_source.owner }
  let(:workspace) { workspaces(:real) }
  let(:database) { GreenplumIntegration.real_database }
  let(:schema) { database.schemas.find_by_name('test_schema') }
  let(:account) { GreenplumIntegration.real_account }
  let(:gpdb_data_source) { GreenplumIntegration.real_data_source }

  let(:import) do
    WorkspaceImport.new.tap do |i|
      i.workspace = workspace
      i.to_table = 'new_table1234'
      i.new_table = true
      i.source_dataset = i.workspace.sandbox.datasets.find_by_name('candy_one_column')
      i.user = user
    end
  end

  before { workspace.update_attribute :sandbox_id, schema.id }

  describe "associations" do
    it { should belong_to(:source_dataset).class_name('Dataset') }
    it { should belong_to :user }
  end

  describe "validations" do
    it "validates the presence of to_table" do
      import = FactoryGirl.build(:import, :workspace => workspace, :user => user, :to_table => nil)
      import.should_not be_valid
      import.should have_error_on(:to_table)
    end

    it "validates the presence of source_dataset if no file_name present" do
      import = FactoryGirl.build(:import, :workspace => workspace, :user => user, :source_dataset => nil, :file_name => nil)
      import.should_not be_valid
      import.should have_error_on(:source_dataset)
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
      stub(import.source_dataset).dataset_consistent? { false }
      import.to_table = 'pg_all_types'
      import.new_table = false
      import.should_not be_valid

      import.should have_error_on(:base, :table_not_consistent)
    end

    it "sets the destination_dataset before validation" do
      stub(import.source_dataset).dataset_consistent? { true }
      import.to_table = 'master_table1'
      import.new_table = false
      import.should be_valid
      import.destination_dataset.should == import.workspace.sandbox.datasets.find_by_name('master_table1')
    end

    it "should change a previously set destination dataset" do
      stub(import.source_dataset).dataset_consistent? { true }
      import.destination_dataset = import.source_dataset
      import.to_table = 'master_table1'
      import.new_table = false
      import.should be_valid
      import.destination_dataset.should == import.workspace.sandbox.datasets.find_by_name('master_table1')
    end

    it "is valid if an imports table become inconsistent after saving" do
      import.save
      stub(import.source_dataset).dataset_consistent? { false }

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
end
