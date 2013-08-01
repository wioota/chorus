require 'spec_helper'

class FakeJobTask < JobTask
  def execute
    @@order << index
  end
end

@@order = []

describe Job do
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
  end

  describe '#create!' do
    let(:attrs) { FactoryGirl.attributes_for(:job) }

    it "is disabled by default" do
      job = Job.create! attrs
      job.should_not be_enabled
    end
  end

  describe 'scheduling' do
    describe '.ready_to_run' do
      let!(:job1) { job = jobs(:ready); job.update_attribute(:next_run, 55.seconds.ago); job }
      let!(:job2) { FactoryGirl.create(:job, :next_run => 30.seconds.ago, :enabled => true) }
      let!(:job3) { FactoryGirl.create(:job, :next_run => 1.day.from_now, :enabled => true) }
      let!(:job4) { FactoryGirl.create(:job, :next_run => 1.day.ago, :enabled => false) }

      it "returns only jobs that should have run by now" do
        Job.ready_to_run.should == [job1, job2]
      end

      it "only returns jobs that are enabled" do
        Job.ready_to_run.should == [job1, job2]
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
      let(:job) { jobs(:ready) }

      it 'puts itself into the worker queue if not already there' do
        mock(QC.default_queue).enqueue_if_not_queued("Job.run", job.id)
        job.enqueue
      end

      it "sets the job's status to waiting to run" do
        job.enqueue
        job.reload.status.should == 'enqueued'
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
      let(:job) { jobs(:ready) }

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

      it 'updates the status to "running"' do
        job.run
        job.status.should == 'running'
      end

      context "if the end_run date is before the new next_run" do
        let(:expiring_job) do
          jobs(:default).tap do |job|
            job.end_run = Time.current
            job.enable!
            job.save!
          end
        end

        it 'disables the job' do
          stub(expiring_job).execute_tasks { raise JobTask::JobTaskFailure }
          expect do
            expiring_job.run
          end.to change(expiring_job, :enabled).from(true).to(false)
        end

      end

      describe 'executing each task' do

        let(:job) do
          job = FactoryGirl.create(:job)
        end

        let(:tasks) do
          3.times.map { |i| FakeJobTask.create({:index => i, :job => job, :action => 'import_source_data'}) }
        end

        before do
          tasks.reverse.each do |task|
            job.job_tasks << task
          end
        end

        it 'is done in index order' do
          job.run
          @@order.length.should == 3
          @@order.should == @@order.sort
        end
      end
    end

    describe 'success' do
      let(:job) { jobs(:ready) }

      before { stub(job).execute_tasks { true } }

      it "creates a JobSucceeded event" do
        expect do
          job.run
        end.to change(Events::JobSucceeded, :count).by(1)
      end
    end

    describe 'failure' do
      let(:job) { jobs(:ready) }

      before { stub(job).execute_tasks { raise JobTask::JobTaskFailure } }

      it "creates a JobFailed event" do
        expect do
          job.run
        end.to change(Events::JobFailed, :count).by(1)
      end
    end
  end
end