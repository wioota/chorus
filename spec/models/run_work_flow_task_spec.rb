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
    it "should work" do
      expect {
        RunWorkFlowTask.assemble!(task_plan, job)
      }.to change(RunWorkFlowTask, :count).by(1)
    end

    it "should have a reference to the workflow" do
      RunWorkFlowTask.assemble!(task_plan, job).work_flow.should == work_flow
    end
  end
end
