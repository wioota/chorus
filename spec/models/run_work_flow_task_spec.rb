require 'spec_helper'

describe RunWorkFlowTask do
  let(:work_flow) { AlpineWorkfile.first }
  let(:job) { jobs(:default) }
  let(:task_plan) do
    {
        :work_flow_id => work_flow.id,
        :action => 'run_work_flow'
    }
  end

  describe ".assemble!" do
    it "creates a new JobTask associated with the job" do
      expect {
        expect {
          JobTask.assemble!(task_plan, job)
        }.to change(RunWorkFlowTask, :count).by(1)
      }.to change(job.job_tasks, :count).by(1)
    end


    it "should have a reference to the workflow as payload" do
      JobTask.assemble!(task_plan, job).reload.payload.should == work_flow
    end
  end

  describe "#build_task_name" do
    let(:task) { job_tasks(:rwft) }
    it "includes the file_name" do
      task.build_task_name.should include(task.payload.file_name)
    end
  end
end
