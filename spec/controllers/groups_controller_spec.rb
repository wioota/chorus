require 'spec_helper'

describe GroupsController do
  let(:user) { users(:owner) }
  let (:a_group) { groups(:a_group) }

  before do
    log_in user
  end

  describe '#index' do
    before :each do
      get :index
    end

    it_behaves_like "an action that requires authentication", :get, :index

    it "succeeds" do
      response.code.should == "200"
    end

    it "returns a list of groups" do
      response.decoded_body.length.should == Group.count
    end
  end

  describe '#create' do
    let (:params) {
      {
          :name => "new_group",
          :description => "here's that new group you're always talking about"
      }
    }
    before :each do
      post :create, params
    end

    it_behaves_like "an action that requires authentication", :post, :create

    it "should create a group" do
      Group.find_by_name(params[:name]).should be_present
    end
  end

  describe '#new' do
  end

  describe '#edit' do
  end

  describe '#show' do

    it "succeeds when the group exists" do
      get :show, :id => a_group.id
      response.should be_success
    end

    it "finds the right group" do
      get :show, :id => a_group.id
      response.decoded_body.id.should == a_group.id
      response.decoded_body.name.should == a_group.name
      response.decoded_body.description.should == a_group.description
    end

    it "fails when the group doesn't exist" do
      get :show, :id => 'garbage_id'
      response.should be_not_found
    end
  end

  describe '#update' do
    let (:old_params ){
      {
          :id => a_group.id,
          :name => a_group.name,
          :description => a_group.description
      }
    }

    let (:new_params) {
      {
          :name => 'different name',
          :description => 'different description'
      }
    }

    it "updates the correct attributes" do
      put :update, old_params.merge(:group => new_params)
      response.decoded_body.name.should == new_params[:name]
      response.decoded_body.description.should == new_params[:description]
    end
  end

  describe '#destroy' do
    let (:new_group) { FactoryGirl.create(:group, :name => "destory me!") }

    it "destroys the group given the proper id" do
      old_count = Group.count
      new_group

      Group.count.should == old_count + 1
      delete :destroy, { :id => new_group.id }
      Group.count.should == old_count
    end
  end
end
