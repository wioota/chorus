require 'spec_helper'

describe JobsController do
  describe '#create' do
    before { log_in user }
    let(:user) { users(:owner) }
    let(:workspace) { workspaces(:public) }
    let(:post_params) do
      {
        :workspace_id => workspace,
        :name => "Weekly TPS Reports"
      }
    end

    it "returns 201" do
      post :create, post_params
      response.code.should == "201"
    end

    it "creates a Job" do
      expect do
        post :create, post_params
      end.to change(Job, :count).by(1)
    end
  end
end