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

    it "validates the presence of source_dataset" do
      import = FactoryGirl.build(:import, :workspace => workspaces(:real), :source_dataset => nil)
      import.valid?
      import.should have_at_least(1).errors_on(:source_dataset)
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

    it "validates that to_table exists if new_table is false" do
      import.new_table = false
      import.to_table = 'hello12345'
      import.should_not be_valid

      import.errors.messages[:base].select { |a,b| a == :table_not_exists }.should_not be_empty
    end
  end

  describe "#run" do
    let(:user) { users(:owner) }
    let(:source_table) { datasets(:table) }
    let(:workspace) { workspaces(:public) }
    let(:import) do
      Import.create!(
          {
              :source_dataset => source_table,
              :user => user,
              :workspace => workspace
          }.merge(import_attributes),
          :without_protection => true
      )
    end
    let(:import_attributes) do
      {
          :to_table => "the_new_table",
          :new_table => true,
          :sample_count => 20,
          :truncate => false
      }
    end
    let(:expected_attributes) do
      import_attributes.merge(
          :workspace_id => workspace.id,
          :import_id => import.id
      )
    end

    let(:import_schedule) {
      ImportSchedule.create!({:start_datetime => '2012-09-04 23:00:00-07',
                              :end_date => '2012-12-04',
                              :frequency => 'weekly',
                              :workspace => workspace,
                              :to_table => "the_new_table",
                              :source_dataset => source_table,
                              :truncate => true,
                              :new_table => true,
                              :user => user},
                             :without_protection => true)
    }

    context "when copying between different databases" do
      before do
        workspace.sandbox = gpdb_schemas(:searchquery_schema)
        workspace.save!
        workspace.sandbox.database.id.should_not == source_table.schema.database.id
      end

      it "calls Gppipe.run_import" do
        mock(Gppipe).run_import(source_table.id, user.id, expected_attributes)
        Import.run(import.id)
      end
    end

    context "when importing within the same database" do
      it "calls GpTableCopier.run_import" do
        mock(GpTableCopier).run_import(source_table.id, user.id, expected_attributes)
        Import.run(import.id)
      end
    end

    context "update the schedule information " do
      before do
        import.import_schedule = import_schedule
        import.save!
      end
      context "when import into new_table" do
        before do
          stub(GpTableCopier).run_import(source_table.id, user.id, expected_attributes)
          Import.run(import.id)
        end

        it "updates new_table attributes to false if import is successful" do
          import.reload.import_schedule.new_table.should == false
        end
      end

      context "if the import fail" do
        before do
          stub(GpTableCopier).run_import(source_table.id, user.id, expected_attributes) {
            raise Exception
          }
          begin
            Import.run(import.id)
          rescue Exception
          end
        end

        it "does not update 'new_table' attribute" do
          import.reload.import_schedule.new_table.should == true
        end
      end
    end
  end
end