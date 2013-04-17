require 'spec_helper'

describe WorkspaceDatasetsController, :greenplum_integration => true, :type => :controller do
  before { log_in user }

  context "when the dataset is an Oracle table" do
    let(:user) { users(:owner) }
    let(:dataset) { datasets(:oracle_table) }
    let(:workspace) { workspaces(:public) }
    let(:params) do
      {:dataset_ids => [dataset.to_param], :workspace_id => workspace.to_param}
    end

    it "does not process the entity" do
      expect do
        post :create, params
      end.to_not change { workspace.source_datasets.count }

      response.code.should == "422"
    end
  end
end