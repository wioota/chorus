require 'spec_helper'
require 'will_paginate/array'

describe JobsController do
  let(:user) { users(:owner) }
  let(:workspace) { workspaces(:public) }

  before do
    log_in user
  end

  describe "#index" do
    it "responds with jobs but without their associated tasks" do
      get :index, :workspace_id => workspace.id
      response.code.should == "200"
      decoded_response[0][:tasks].should be_nil
    end

    it "sorts by name by default" do
      get :index, :workspace_id => workspace.id
      names = decoded_response.map { |job| job.name }
      names.should == names.sort
    end

    it "sorts by next run" do
      get :index, :workspace_id => workspace.id, :order => "next_run"
      timestamps = decoded_response.map { |job| job.next_run }
      timestamps.compact.should == timestamps.compact.sort
    end

    describe "pagination" do
      let(:sorted_jobs) { workspace.jobs.sort_by! { |job| job.name.downcase } }

      it "defaults the per_page to fifty" do
        get :index, :workspace_id => workspace.id
        request.params[:per_page].should == 50
      end

      it "paginates the collection" do
        get :index, :workspace_id => workspace.id, :page => 1, :per_page => 2
        decoded_response.length.should == 2
      end

      it "defaults to page one" do
        get :index, :workspace_id => workspace.id, :per_page => 2
        decoded_response.length.should == 2
        decoded_response.first.id.should == sorted_jobs.first.id
      end

      it "accepts a page parameter" do
        get :index, :workspace_id => workspace.id, :page => 2, :per_page => 2
        decoded_response.length.should == 2
        decoded_response.first.id.should == sorted_jobs[2].id
        decoded_response.last.id.should == sorted_jobs[3].id
      end
    end

    generate_fixture "jobSet.json" do
      get :index, :workspace_id => workspace.id
    end
  end

  describe '#show' do
    let(:job) { jobs(:default) }

    it "responds with a job and its associated tasks" do
      get :show, :workspace_id => workspace.id, :id => job.id
      response.code.should == "200"
      decoded_response[:id].should == job.id
      decoded_response[:tasks].should_not be_nil
    end

    generate_fixture "job.json" do
      get :show, :workspace_id => workspace.id, :id => job.id
    end
  end

  describe '#create' do
    let(:planned_job) { FactoryGirl.attributes_for(:job) }
    let(:params) do
      {
          :workspace_id => workspace.id,
          :job => planned_job
      }
    end

    it "uses authorization" do
      mock(subject).authorize! :can_edit_sub_objects, workspace
      post :create, params
    end

    it "returns 201" do
      post :create, params
      response.code.should == "201"
    end

    it "creates a Job" do
      expect do
        post :create, params
      end.to change(Job, :count).by(1)
    end

    it "adds a created Job with a given Workspace" do
      expect do
        post :create, params
      end.to change { workspace.reload.jobs.count }.by(1)
    end

    it 'renders the created job as JSON' do
      post :create, params
      response.code.should == "201"
      decoded_response.should_not be_empty
    end

    context "on demand" do
      let(:params) {
        {
          :job => {
            :workspace => {:id => workspace.id},
            :name => "asd",
            :interval_unit => "on_demand",
            :interval_value => "0",
            :next_run => "invalid",
            :end_run => "invalid",
            :time_zone => "Hawaii"
          },
          :workspace_id => workspace.id
        }
      }

      it "creates an on demand job" do
        expect do
          post :create, params
        end.to change(Job, :count).by(1)
      end
    end
  end

  describe '#update' do
    let(:job) { FactoryGirl.create(:job, workspace: workspace, enabled: false) }
    let(:params) do
      {
        id: job.id,
        workspace_id: workspace.id,
        job: {
            enabled: true,
            next_run: "2013-07-30T14:00:00-00:00",
            time_zone: 'Arizona'
        }
      }
    end

    it "uses authorization" do
      mock(subject).authorize! :can_edit_sub_objects, workspace
      put :update, params
    end

    it "updates a job" do
      expect do
        put :update, params
        job.reload
      end.to change(job, :enabled).from(false).to(true)
    end

    it "applies the passed-in time zone to the passed-in next_run without shifting time" do
      put :update, params
      job.reload.next_run.to_i.should == DateTime.parse("2013-07-30T14:00:00-07:00").to_i
    end
  end

  describe '#destroy' do
    let(:job) { jobs(:default) }
    let(:params) do
      { workspace_id: workspace.id, id: job.id }
    end

    it "lets a workspace member soft delete an job" do
      delete :destroy, params
      response.should be_success
      job.reload.deleted?.should be_true
    end

    it "uses authorization" do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      delete :destroy, params
    end
  end
end