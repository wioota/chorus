require 'spec_helper'

describe Kaggle::UsersController do
  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe "#index" do
    it_behaves_like "an action that requires authentication", :get, :index, :workspace_id => '-1'

    it "succeeds" do
      get :index, :workspace_id => '-1'
      response.code.should == "200"
    end

    it "shows list of users" do
      get :index, :workspace_id => '-1'
      decoded_response.length.should > 0
    end

    it "presents the kaggle users" do
      mock_present { |kaggle_users|
        kaggle_users.first.should be_a KaggleUser
      }

      get :index, :workspace_id => '-1'
      response.should be_success
    end

    it "sorts by rank" do
      stub.proxy(KaggleApi).users(anything) do |users|
        users.sort_by { |user| -user['rank'] }
      end

      mock_present { | kaggle_users|
       kaggle_users.first.rank.should <= kaggle_users.second.rank
      }

      get :index, :workspace_id => '-1'
    end

    it "sends the filters to the KaggleApi.users method" do
      filters = ['i am a filter']
      mock(KaggleApi).users(:filters => filters) { [] }
      get :index, :workspace_id => '-1', :filters => filters
    end

    generate_fixture "kaggleUserSet.json" do
      get :index, :workspace_id => '-1'
    end
  end
end