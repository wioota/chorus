require 'spec_helper'

describe Job do
  let(:ready_job) { FactoryGirl.create(:job, :next_run => 1.second.ago) }

  describe 'validations' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :interval_unit }
    it { should validate_presence_of :interval_value }
    it { should ensure_inclusion_of(:interval_unit).in_array(Job::VALID_INTERVAL_UNITS) }
    it { should ensure_inclusion_of(:status).in_array(Job::STATUSES) }
    it { should have_many :job_tasks }

    describe "name uniqueness validation" do
      let(:workspace) { workspaces(:public) }
      let(:other_workspace) { workspaces(:private) }
      let(:existing_job) { workspace.jobs.first! }

      it "is invalid if a job in the workspace has the same name" do
        new_job = FactoryGirl.build(:job, :name => existing_job.name, :workspace => workspace)
        new_job.should_not be_valid
        new_job.should have_error_on(:name)
      end

      it "enforces uniqueness only among non-deleted jobs" do
        existing_job.destroy
        new_job = FactoryGirl.build(:job, :name => existing_job.name, :workspace => workspace)
        new_job.should be_valid
      end

      it "is valid if a job in another workspace has the same name" do
        new_job = FactoryGirl.build(:job, :name => existing_job.name, :workspace => other_workspace)
        new_job.should be_valid
      end

      it "is invalid if you change a name to an existing name" do
        new_job = FactoryGirl.build(:job, :name => 'totally_unique', :workspace => workspace)
        new_job.should be_valid
        new_job.name = existing_job.name
        new_job.should_not be_valid
      end
    end

    describe "next_run validations" do
      it "is invalid if the next_run is in the past" do
        new_job = FactoryGirl.build(:job, :next_run => 1.hour.ago)
        new_job.should_not be_valid
        new_job.should have_error_on(:job)
      end
    end
  end

  describe '#create!' do
    let(:attrs) { FactoryGirl.attributes_for(:job) }

    it "saves a disabled Job by default" do
      job = Job.create! attrs
      job.should_not be_enabled
    end
  end

  describe 'scheduling' do
    describe '.ready_to_run' do
      let(:job1) do
        temp = FactoryGirl.build(:job, :name => 'past_enabled', :next_run => 30.seconds.ago, :enabled => true)
        temp.save!(:validate => false)
        temp
      end
      let(:job2) { FactoryGirl.create(:job, :name => 'future_enabled', :next_run => 1.day.from_now, :enabled => true) }
      let(:job3) do
        temp = FactoryGirl.build(:job, :name => 'past_disabled', :next_run => 1.day.ago, :enabled => false)
        temp.save!(:validate => false)
        temp
      end

      before do
        Job.delete_all
        [job1, job2, job3] # Initialize lets
      end

      it "returns only enabled jobs that should have run by now" do
        Job.ready_to_run.all.should == [job1]
      end
    end

    describe '.run' do
      let(:job) do
        jobs(:default).tap { |job| mock(job).run }
      end

      it "tells the given job to run itself" do
        mock(Job).find(job.id) { job }
        Job.run job.id
      end
    end

    describe '#enqueue' do
      it 'puts itself into the worker queue if not already there' do
        mock(QC.default_queue).enqueue_if_not_queued("Job.run", ready_job.id)
        ready_job.enqueue
      end

      it "sets the job's status to waiting to run" do
        ready_job.enqueue
        ready_job.reload.status.should == 'enqueued'
      end
    end
  end

  describe '#run' do
    context "for on demand jobs" do
      # todo
      #it 'updates the next run time' do
      #  og_next_run = job.next_run
      #  Timecop.freeze do
      #    job.run
      #    job.next_run.to_i.should == job.frequency.since(og_next_run).to_i
      #  end
      #end
    end

    context "for scheduled jobs" do
      let(:job) { ready_job }

      it 'updates the next run time' do
        og_next_run = job.next_run
        Timecop.freeze do
          job.run
          job.next_run.to_i.should == job.frequency.since(og_next_run).to_i
        end
      end

      it 'updates the last run time' do
        Timecop.freeze do
          job.run
          job.last_run.to_i.should == Time.current.to_i
        end
      end

      context "when the job finishes running" do
        it 'updates the status to "idle"' do
          job.run
          job.status.should == 'idle'
        end
      end

      context "if the end_run date is before the new next_run" do
        let(:expiring_job) do
          FactoryGirl.create(:job, :interval_unit => "weeks", :next_run => Time.current, :end_run => 1.day.from_now.to_date, enabled: true, workspace: workspaces(:public))
        end

        it 'disables the job' do
          stub(expiring_job).execute_tasks { true }
          expect do
            expiring_job.run
          end.to change(expiring_job, :enabled).from(true).to(false)
        end
      end

      context "if there is no end_run" do
        let(:forever_job) do
          jobs(:default).tap do |job|
            job.end_run = nil
            job.enable!
            job.save!
          end
        end
        it 'does not disable the job' do
          stub(forever_job).execute_tasks { true }
          expect do
            forever_job.run
          end.to_not change(forever_job, :enabled)
        end
      end

      describe 'executing each task' do
        class FakeJobTask < JobTask
          Order = []

          def execute
            Order << index
          end
        end

        let(:job) { FactoryGirl.create(:job) }
        let!(:tasks) do
          3.times.map { FactoryGirl.create(:job_task, job: job, type: 'FakeJobTask') }
        end

        it 'is done in index order' do
          job.run
          FakeJobTask::Order.length.should == 3
          FakeJobTask::Order.should == FakeJobTask::Order.sort
        end
      end
    end

    describe 'success' do
      let(:job) { ready_job }

      before { stub(job).execute_tasks { true } }

      it "creates a JobSucceeded event" do
        expect do
          job.run
        end.to change(Events::JobSucceeded, :count).by(1)
      end
    end

    describe 'failure' do
      let(:job) { ready_job }

      before { stub(job).execute_tasks { raise JobTask::JobTaskFailure } }

      it "creates a JobFailed event" do
        expect do
          job.run
        end.to change(Events::JobFailed, :count).by(1)
      end
    end
  end

  describe 'on update' do
    context 'with an on demand job' do
      let(:job) { jobs(:on_demand) }

      it 'does not error' do
        job.save!
      end
    end

    context 'with a scheduled job' do
      let(:impossible_job) { FactoryGirl.create(:job, :next_run => 1.hour.from_now, :end_run => Time.current) }

      it 'disables expiring jobs on update' do
        impossible_job.save!
        impossible_job.should_not be_enabled
      end
    end
  end

  describe '#enable!' do
    Timecop.freeze do
      let(:job) do
        job = FactoryGirl.create(:job, :enabled => false, :interval_unit => "hours", :interval_value => 1)
        job.update_attribute(:next_run, 55.minutes.ago)
        job
      end

      it 'increments the next run to the next valid time' do
        job.enable!
        job.next_run.to_i.should == 5.minutes.from_now.to_i
      end
    end
  end
end