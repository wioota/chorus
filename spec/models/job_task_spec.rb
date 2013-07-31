require 'spec_helper'

describe JobTask do
  it { should validate_presence_of :index }
  it { should validate_presence_of :action }
  it { should ensure_inclusion_of(:action).in_array(%w( import_source_data run_work_flow run_sql_file )) }
  it { should validate_presence_of :job }
  it { should belong_to(:job) }

  describe 'create #build_for_action!' do
    let(:workspace) { workspaces(:empty_workspace) }
    let(:user) { users(:owner) }
    let(:dataset) { datasets(:table) }
    let(:job) { jobs(:default) }

    let(:planned_job_task) do
      {
        :action => 'import_source_data',
        :source_id => dataset.id,
        :destination_id => '2',
        :row_limit => '500',
        :truncate => false
      }
    end

    let(:params) do
      {
        :workspace_id => workspace.id,
        :job_id => job.id,
        :job_task => planned_job_task
      }
    end

    it 'adds the task to the job' do
      expect {
        JobTask.create_for_action!(params)
      }.to change(job.job_tasks, :count).by(1)
    end

    it "chooses a non-conflicting index" do
      doomed_task = JobTask.create_for_action!(params)
      JobTask.create_for_action!(params)
      doomed_task.destroy
      JobTask.create_for_action!(params)
    end
  end
end