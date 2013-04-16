require 'spec_helper'

describe ImportSchedule, :greenplum_integration do
  let(:import_schedule) { import_schedules(:default) }
  let(:database) { GreenplumIntegration.real_database }
  let(:schema) { database.schemas.find_by_name('test_schema') }
  let(:user) { schema.data_source.owner }
  let(:account) { GreenplumIntegration.real_account }
  let(:gpdb_data_source) { GreenplumIntegration.real_data_source }
  let(:workspace) { workspaces(:public) }

  before do
    workspace.update_attribute :sandbox_id, schema.id
    import_schedule.user = user
    import_schedule.workspace = workspace
  end

  describe "validations" do
    context "with an archived workspace" do
      let(:workspace) { workspaces(:archived) }

      it "is not valid if the workspace is archived" do
        schedule = FactoryGirl.build(:import_schedule, :workspace => workspace, :user => user)

        schedule.should have_at_least(1).error_on(:workspace)
      end

      it "is valid if the import schedule is deleted and the workspace is archived" do
        schedule = FactoryGirl.build(:import_schedule, :workspace => workspace, :user => user,
                                     :deleted_at => Time.current)

        schedule.should be_valid
      end
    end

    context "with a non-archived workspace" do
      it "is not valid with unsupported frequencies" do
        schedule = FactoryGirl.build(:import_schedule, :workspace => workspace, :user => user,
                                     :frequency => 'tri-weekly',)

        schedule.should have_at_least(1).error_on(:frequency)
      end

      it "sets the destination_dataset before validation" do
        import_schedule.new_table = false
        import_schedule.to_table = 'base_table1'
        any_instance_of(GpdbDataset) do |dataset|
          stub(dataset).can_import_into(anything) { true }
        end
        import_schedule.should be_valid
        import_schedule.destination_dataset.name.should == 'base_table1'
      end

      describe "with stale datasets" do
        it "table_does_exist talks to greenplum" do
          import_schedule.new_table = false

          table = FactoryGirl.create(:gpdb_table, :name => "dropped_table", :schema => schema)
          import_schedule.to_table = 'dropped_table'

          import_schedule.table_does_exist.should be_false
          import_schedule.table_does_not_exist.should be_true

          import_schedule.should_not be_valid
        end
      end
    end

    def it_validates_that_table_does status
      if status == :exist
        mock(import_schedule).table_does_exist
        dont_allow(import_schedule).table_does_not_exist
      end

      if status == :not_exist
        mock(import_schedule).table_does_not_exist
        dont_allow(import_schedule).table_does_exist
      end

      import_schedule.valid?
    end

    def it_does_not_validate_table
      dont_allow(import_schedule).table_does_exist
      dont_allow(import_schedule).table_does_not_exist

      import_schedule.valid?
    end

    context "when new_table is true" do
      before do
        import_schedule.new_table = true
        import_schedule.save(:validate => false)
      end

      it "validates table_does_not_exist if the to_table has changed" do
        import_schedule.to_table = 'something_new'
        it_validates_that_table_does :not_exist
      end

      it "does not validate table_does_not_exist if the to_table has not changed" do
        dont_allow(import_schedule).table_does_not_exist
        it_does_not_validate_table
      end
    end

    context "when new_table is false" do
      before do
        import_schedule.new_table = false
        import_schedule.save(:validate => false)
      end

      it "validates table_does_exist if the to_table has changed" do
        import_schedule.to_table = 'something_new'
        it_validates_that_table_does :exist
      end

      it "does not validate table_does_exist if the to_table has not changed" do
        it_does_not_validate_table
      end

      it "validates table_does_not_exist when new_table is changed to true" do
        import_schedule.new_table = true
        it_validates_that_table_does :not_exist
      end
    end

    it "does not validate associated imports" do
      import = import_schedule.imports.build
      import.errors.add(:base, "something terrible")
      import_schedule.should be_valid
    end
  end

  describe "callbacks" do
    let(:start_day) { Time.current + 2.days }
    let(:next_year) { Time.current + 1.year }

    describe "before saving, automatically updating the next_import_at attribute" do
      context "when the start date is changed to be sooner in the future" do

        let(:import_schedule) do
          FactoryGirl.create(:import_schedule,
                             :start_datetime => next_year,
                             :end_date => next_year + 1.year,
                             :workspace => workspace,
                             :user => user
          )
        end

        it "updates the next_import_at attribute" do
          import_schedule.next_import_at.should == next_year

          import_schedule.start_datetime = start_day
          import_schedule.end_date = next_year
          import_schedule.frequency = 'daily'
          import_schedule.save!

          import_schedule.next_import_at.should == start_day
        end

      end
    end
  end

  describe "associations" do
    it { should belong_to(:scoped_workspace).class_name('Workspace') }
    it { should belong_to(:scoped_source_dataset).class_name('Dataset') }
    it { should belong_to :user }
    it { should have_many :imports }
  end

  describe "default scope" do
    it "does not show deleted schedules" do
      active_schedule = FactoryGirl.create(:import_schedule,
                                           :workspace => workspace,
                                           :user => user,
                                           :start_datetime => Time.current,
                                           :end_date => Time.current + 1.year,
                                           :frequency => 'monthly')
      deleted_schedule = FactoryGirl.create(:import_schedule,
                                            :workspace => workspace,
                                            :user => user,
                                            :deleted_at => Time.current,
                                            :start_datetime => Time.current,
                                            :end_date => Time.current + 1.year,
                                            :frequency => 'monthly')
      ImportSchedule.all.should include(active_schedule)
      ImportSchedule.all.should_not include(deleted_schedule)
    end
  end

  describe ".ready_to_run scope" do
    it "shows import schedules that should be run" do
      ready_schedule = FactoryGirl.create(:import_schedule, :workspace => workspace,
                                          :start_datetime => Time.current + 1.minute,
                                          :user => user,
                                          :end_date => Time.current + 1.year,
                                          :frequency => 'monthly')
      deleted_schedule = FactoryGirl.create(:import_schedule,
                                            :workspace => workspace,
                                            :user => user,
                                            :deleted_at => Time.current,
                                            :start_datetime => Time.current + 1.minute,
                                            :end_date => Time.current + 1.year,
                                            :frequency => 'monthly')
      not_ready_schedule = FactoryGirl.create(:import_schedule,
                                              :workspace => workspace,
                                              :start_datetime => Time.current + 1.year,
                                              :user => user,
                                              :end_date => Time.current + 1.year,
                                              :frequency => 'monthly')

      Timecop.freeze(Time.current + 1.day) do
        ImportSchedule.ready_to_run.should include(ready_schedule)
        ImportSchedule.ready_to_run.should_not include(deleted_schedule, not_ready_schedule)
      end
    end
  end

  describe "#create_import" do
    let(:import_schedule) { import_schedules(:default) }

    before do
      any_instance_of(Import) do |import|
        stub(import).table_does_exist { raise 'bang!' }
        stub(import).tables_have_consistent_schema { true }
      end
    end

    it "creates an import with source/destination info without checking if destination table exists" do
      import = import_schedule.create_import

      import.workspace_id.should == import_schedule.workspace_id
      import.to_table.should == import_schedule.to_table
      import.source_id.should == import_schedule.source_dataset_id
      import.truncate.should == import_schedule.truncate
      import.user_id.should == import_schedule.user_id
      import.sample_count.should == import_schedule.sample_count
      import.should be_persisted
    end
  end

  describe "#source_dataset" do
    let(:source_dataset) { import_schedule.source_dataset }

    it "returns source_dataset even if it is deleted" do
      import_schedule.source_dataset.should == source_dataset
      source_dataset.destroy
      import_schedule.reload.source_dataset.should == source_dataset
    end
  end

  describe "#workspace" do
    it "returns workspace even if it is deleted" do
      import_schedule.workspace.should == workspace
      workspace.destroy
      import_schedule.reload.workspace.should == workspace
    end
  end
end
