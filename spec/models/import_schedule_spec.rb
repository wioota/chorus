require 'spec_helper'

describe ImportSchedule do
  let(:import_schedule) { import_schedules(:default) }

  describe "validations" do
    it "should not be valid if the workspace is archived" do
      schedule = FactoryGirl.build(:import_schedule, :workspace => workspaces(:archived))
      schedule.should have_at_least(1).error_on(:workspace)
    end

    it "is not valid with unsupported frequencies" do
      schedule = FactoryGirl.build(:import_schedule, :frequency => 'tri-weekly', :workspace => workspaces(:public))
      schedule.should have_at_least(1).error_on(:frequency)
    end
  end

  describe "callbacks:" do
    describe "before saving, automatically updating the next_import_at attribute" do
      context "when the start date is changed to be sooner in the future" do
        let(:start_day) { Time.now + 2.days }
        let(:next_year) { Time.now + 1.year }
        let(:import_schedule) do
          FactoryGirl.create(:import_schedule,
                              :start_datetime => next_year,
                              :end_date => next_year + 1.year,
                              :workspace => workspaces(:public))
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
    it { should belong_to :workspace }
    it { should belong_to(:source_dataset).class_name('Dataset') }
    it { should belong_to :user }
    it { should have_many :imports }
  end

  describe "default scope" do
    it "excludes deleted import schedules" do
      new_import_schedule = FactoryGirl.create(:import_schedule,
                                               :workspace => workspaces(:public),
                                               :deleted_at => nil)
      deleted_import_schedule = FactoryGirl.create(:import_schedule,
                                                   :workspace => workspaces(:public),
                                                   :deleted_at => Time.now)
      ImportSchedule.all.should include(new_import_schedule)
      ImportSchedule.all.should_not include(deleted_import_schedule)
    end
  end

  describe "default scope" do
    it "does not show deleted schedules" do
      active_schedule = FactoryGirl.create(:import_schedule, :workspace => workspaces(:public), :start_datetime => Time.now, :end_date => Time.now + 1.year, :frequency => 'monthly')
      deleted_schedule = FactoryGirl.create(:import_schedule, :workspace => workspaces(:public), :deleted_at => Time.now, :start_datetime => Time.now, :end_date => Time.now + 1.year, :frequency => 'monthly')
      ImportSchedule.all.should include(active_schedule)
      ImportSchedule.all.should_not include(deleted_schedule)
    end
  end

  describe ".ready_to_run scope" do
    it "shows import schedules that should be run" do
      ready_schedule = FactoryGirl.create(:import_schedule, :workspace => workspaces(:public),
                                          :start_datetime => Time.now + 1.minute,
                                          :end_date => Time.now + 1.year,
                                          :frequency => 'monthly')
      deleted_schedule = FactoryGirl.create(:import_schedule,
                                            :workspace => workspaces(:public),
                                            :deleted_at => Time.now,
                                            :start_datetime => Time.now + 1.minute,
                                            :end_date => Time.now + 1.year,
                                            :frequency => 'monthly')
      not_ready_schedule = FactoryGirl.create(:import_schedule,
                                              :workspace => workspaces(:public),
                                              :start_datetime => Time.now + 1.year,
                                              :end_date => Time.now + 1.year,
                                              :frequency => 'monthly')

      Timecop.freeze(Time.now + 1.day) do
        ImportSchedule.ready_to_run.should include(ready_schedule)
        ImportSchedule.ready_to_run.should_not include(deleted_schedule, not_ready_schedule)
      end
    end
  end
end