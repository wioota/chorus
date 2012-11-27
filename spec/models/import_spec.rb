require 'spec_helper'

describe Import, :database_integration => true do
  describe "associations" do
    it { should belong_to :workspace }
    it { should belong_to(:source_dataset).class_name('Dataset') }
    it { should belong_to :user }
    it { should belong_to :import_schedule }
  end

  describe "validations" do
    let(:import) {
      i = Import.new
      i.workspace = workspaces(:real)
      i.to_table = 'new_table1234'
      i.new_table = true
      i.source_dataset = i.workspace.sandbox.datasets.first
      i.user = users(:owner)
      i
    }

    it "validates the presence of to_table" do
      import = FactoryGirl.build(:import, :workspace => workspaces(:real), :to_table => nil)
      import.valid?
      import.should have_at_least(1).errors_on(:to_table)
    end

    it "validates the presence of source_dataset if no file_name present" do
      import = FactoryGirl.build(:import, :workspace => workspaces(:real), :source_dataset => nil, :file_name => nil)
      import.valid?
      import.should have_at_least(1).errors_on(:source_dataset)
      import.should have_at_least(1).errors_on(:file_name)
    end

    it "does not validate the presence of source_dataset if file_name present" do
      import = FactoryGirl.build(:import, :workspace => workspaces(:real), :source_dataset => nil, :file_name => "foo.csv")
      import.should be_valid
    end

    it "validates the presence of user" do
      import = FactoryGirl.build(:import, :workspace => workspaces(:real), :user => nil)
      import.valid?
      import.should have_at_least(1).errors_on(:user)
    end

    it "validates that the to_table does not exist already if it is a new table" do
      import.to_table = "master_table1"
      import.should_not be_valid
      import.errors.messages[:base].select { |a,b| a == :table_exists }.should_not be_empty
    end

    it "is valid if an old import's to_table exists" do
      import.save
      import.to_table = 'master_table1'
      import.should be_valid
    end

    it "validates that the source and destination have consistent schemas" do
      stub(import.source_dataset).dataset_consistent? { false }
      import.to_table = 'pg_all_types'
      import.new_table = false
      import.should_not be_valid

      import.errors.messages[:base].select { |a,b| a == :table_not_consistent }.should_not be_empty
    end

    it "sets the destination_dataset before validation" do
      stub(import.source_dataset).dataset_consistent? { true }
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
end