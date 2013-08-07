require 'spec_helper'

describe JobTask do
  it { should validate_presence_of :type }
  it { should validate_presence_of :job_id }
  it { should belong_to(:job) }

  describe '#assemble!' do
    let(:workspace) { workspaces(:empty_workspace) }
    let(:user) { users(:owner) }
    let(:dataset) { datasets(:table) }
    let(:job) { jobs(:default) }

    let(:params) do
      {
        :action => 'import_source_data',
        :source_id => dataset.id,
        :destination_id => '2',
        :row_limit => '500',
        :truncate => false
      }
    end

    it 'adds the task to the job' do
      expect {
        JobTask.assemble!(params, job)
      }.to change(job.job_tasks, :count).by(1)
  end

    it "chooses a non-conflicting index" do
      doomed_task = JobTask.assemble!(params, job)
      JobTask.assemble!(params, job)
      doomed_task.destroy
      JobTask.assemble!(params, job)
    end
  end

  describe '#execute' do
    it { should respond_to :execute }
  end

  describe 'deleting' do
    before do
      @job = jobs(:default).tap { |job| job.job_tasks.destroy_all }
      @task1 = FactoryGirl.create(:isdt, index: 1, job: @job)
      @task2 = FactoryGirl.create(:isdt, index: 2, job: @job)
      @task3 = FactoryGirl.create(:isdt, index: 3, job: @job)
    end

    it "compacts indices" do
      @task2.destroy
      @job.job_tasks.reload.map(&:index).should == [1,2]
    end
  end
end