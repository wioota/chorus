require 'spec_helper'
require 'will_paginate/array'

describe MilestonesController do
  let(:user) { users(:owner) }
  let(:workspace) { workspaces(:public) }

  before do
    log_in user
  end

  describe "#index" do
    it "responds with milestones" do
      get :index, :workspace_id => workspace.id
      response.code.should == "200"
      decoded_response.length.should be > 1
      decoded_response.length.should == workspace.milestones.count
    end

    it "sorts by target date by default" do
      get :index, :workspace_id => workspace.id
      target_dates = decoded_response.map { |milestone| milestone.target_date }
      target_dates.should == target_dates.sort
    end

    generate_fixture "milestoneSet.json" do
      get :index, :workspace_id => workspace.id
    end
  end
end