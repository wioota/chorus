require 'spec_helper'

describe JobsController do
  let(:user) { users(:owner) }
  let(:workspace) { workspaces(:public) }

  before do
    log_in user
  end

  describe "#index" do
    it "responds with a success" do
      get :index, :workspace_id => workspace.id
      response.code.should == "200"
    end

    generate_fixture "jobSet.json" do
      get :index, :workspace_id => workspace.id
    end
  end

  describe '#create' do
    let(:post_params) do
      {
        :workspace_id => workspace.id,
        :job => {
          :frequency => 'daily',
          :name => 'Weekly TPS Reports',
          :next_run => 1.day.from_now
        }
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
    #
    #it "presents the created job" do
    #  post :create, post_params
    #  decoded_response.should == post_params[:job]
    #end
  end
end