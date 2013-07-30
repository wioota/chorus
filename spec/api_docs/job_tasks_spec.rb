require 'spec_helper'

resource 'JobTask' do
  before do
    log_in users(:owner)
  end

  post "/workspaces/:workspace_id/jobs/:job_id/job_tasks" do
    parameter :name, "Name"
    parameter :job_id, "Job ID"
    parameter :workspace_id, "Workspace ID"
    parameter :action, "Task Type"
    required_parameters :action, :job_id, :workspace_id

    let(:name) { "TPS reports" }
    let(:workspace_id) { Workspace.first.id }
    let(:job_id) { Job.first.id }
    let(:action) { 'import_source_data' }

    example_request "Create a Job Task in a job in a workspace" do
      status.should == 201
    end
  end

  delete "/workspaces/:workspace_id/jobs/:job_id/job_tasks/:id" do
    parameter :name, "Name"
    parameter :job_id, "Job ID"
    parameter :id, "Job Task ID"

    let(:workspace_id) { Workspace.first.id }
    let(:job_id) { Job.first.id }
    let(:id) { JobTask.first.id }

    example_request "Delete a Job Task in a job in a workspace" do
      status.should == 200
    end
  end
end