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

  describe "#perform" do
    let(:task) { job_tasks(:rwft) }

    it "returns a failure JobTaskResult if it fails to connect to Alpine" do
      stub(Alpine::API).run_work_flow_task(task) { raise StandardError.new('oh no') }
      result = task.perform
      result.name.should == task.name
      result.status.should == JobTaskResult::FAILURE
      result.message.should == 'oh no'
    end

    context "blocking" do
      def wait_until
        Timeout::timeout 10.seconds do
          until yield
            sleep 0.1
          end
        end
      end

      class FakeRunWorkFlowTask < RunWorkFlowTask
        Performed = []

        def perform
          Performed << "start #{id}"
          super
          Performed << "end #{id}"
        end
      end

      self.use_transactional_fixtures = false

      before do
        factory_task = FactoryGirl.create(:run_work_flow_task, job: job, type: 'FakeRunWorkFlowTask')
        @task = JobTask.find(factory_task.id) # re-fetch to ensure it's of FakeRWFT class
      end

      after do
        @task.destroy
      end

      it "blocks while alpine is running the work flow" do
        stub(Alpine::API).run_work_flow_task(@task)
        stub(FakeRunWorkFlowTask).sleep_time { 0.1 }

        Thread.abort_on_exception = true
        thread = Thread.new { @task.perform }

        wait_until { FakeRunWorkFlowTask::Performed == ["start #{@task.id}"] }

        sleep 2

        @task.update_attributes!(:status => 'finished', :payload_result_id => '1234')

        wait_until { FakeRunWorkFlowTask::Performed == ["start #{@task.id}", "end #{@task.id}"] }

        FakeRunWorkFlowTask::Performed.should == ["start #{@task.id}", "end #{@task.id}"]

        thread.kill

        @task.reload.status.should be_nil
        @task.reload.payload_result_id.should == '1234'
      end
    end
  end
end
