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

    it "shows attributes for the users" do
      get :index, :workspace_id => '-1'
      user = decoded_response.first
      user.should have_key('id')
      user.should have_key('username')
      user.should have_key('location')
      user.should have_key('rank')
      user.should have_key('points')
      user.should have_key('number_of_entered_competitions')
      user.should have_key('gravatar_url')
      user.should have_key('full_name')
      user.should have_key('favorite_technique')
      user.should have_key('favorite_software')
    end

    it "sorts by rank" do
      get :index, :workspace_id => '-1'
      decoded_response.first.rank.should <= decoded_response.second.rank
    end

    it "filters the list" do
      get :index, :kaggle_user => ["rank|greater|10"], :workspace_id => '-1'
      decoded_response.length.should == 1
      user = decoded_response.first
      user['rank'].should > 10
    end

    it "filters the list for competition types" do
      get :index, :kaggle_user => ["past_competition_types|equal|Life Sciences"], :workspace_id => '-1'
      decoded_response.length.should == 2
      user = decoded_response.first
      user['past_competition_types'].map(&:downcase).should include(("Life Sciences").downcase)
    end

    it "handles blank filter values" do
      get :index, :kaggle_user => ["rank:greater:|", "past_competition_types|equal|Life Sciences"], :workspace_id => '-1'
      response.should be_success
      decoded_response.length.should == 2
    end

    it "searches software, techniques and location by substring match" do
      get :index, :kaggle_user => ["favorite_technique|includes|svm",
                                   "favorite_software|includes|ggplot2",
                                   "location|includes|SaN FrAnCiScO"], :workspace_id => '-1'
      response.should be_success
      decoded_response.length.should == 1
      user = decoded_response.first
      user['username'].should == 'tstark'
    end

    it "doesn't break if you pass in a number" do
      get :index, :kaggle_user => ["favorite_technique|includes|1234"], :workspace_id => '-1'

      response.should be_success
    end

    it "searches software, techniques and location by substring match" do
      get :index, :kaggle_user => ["favorite_technique|includes|"], :workspace_id => '-1'
      response.should be_success
      decoded_response.length.should == 2
    end

    it "does something ok" do
      get :index, :kaggle_user => ["notakey|includes|foo"], :workspace_id => '-1'
      response.should be_success
      decoded_response.length.should == 0
    end

    generate_fixture "kaggleUserSet.json" do
      get :index, :workspace_id => '-1'
    end
  end
end