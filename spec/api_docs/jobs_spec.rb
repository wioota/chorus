require 'spec_helper'

resource 'Job' do
  before do
    log_in users(:owner)
  end

  post "/workspaces/:workspace_id/jobs" do
    parameter :interval_unit, "Interval Unit"
    parameter :interval_value, "Interval Value"
    parameter :name, "Name"
    parameter :next_run, "Next time to run"
    parameter :workspace_id, "Workspace ID"
    required_parameters :name, :interval_value, :interval_unit, :next_run, :workspace_id


    let(:interval_value) { "1" }
    let(:interval_unit) { "weeks" }
    let(:name) { "TPS reports" }
    let(:next_run) { 3.days.from_now }
    let(:workspace_id) { Workspace.first.id }

    example_request "Create a Job in a workspace" do
      status.should == 201
    end
  end

  get "/workspaces/:workspace_id/jobs" do
    parameter :workspace_id, "Workspace ID"
    required_parameters :workspace_id

    let(:workspace_id) { Workspace.first.id }

    example_request "Display all jobs for a workspace" do
      status.should == 200
    end
  end

  get "/workspaces/:workspace_id/jobs/:id" do
    parameter :workspace_id, "Workspace ID"
    parameter :id, "Job ID"
    required_parameters :id, :workspace_id

    let(:workspace_id) { workspaces(:public).id }
    let(:id) { workspaces(:public).jobs.first.id }

    example_request "Display a given job in a workspace with tasks" do
      status.should == 200
    end
  end
end