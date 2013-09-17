require 'spec_helper'

resource 'Milestone' do
  let(:workspace) { workspaces(:public) }
  let(:workspace_id) { workspace.id }

  before do
    log_in users(:owner)
  end

  get "/workspaces/:workspace_id/milestones" do
    parameter :workspace_id, "Workspace ID"
    required_parameters :workspace_id

    example_request "Display all milestones for a workspace" do
      status.should == 200
    end
  end
end