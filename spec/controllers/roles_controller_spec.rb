require 'spec_helper'

describe RolesController do
  let(:user) { users(:owner) }
  let (:a_role) { roles(:a_role) }

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

    it "returns a list of roles" do
      response.decoded_body.length.should == Role.count
    end
  end

  describe '#create' do
    let (:params) {
      {
          :name => "new_role",
          :description => "here's that new role you're always talking about"
      }
    }
    before :each do
      post :create, params
    end

    it_behaves_like "an action that requires authentication", :post, :create

    it "should create a role" do
      Role.find_by_name(params[:name]).should be_present
    end
  end

  describe '#new' do
  end

  describe '#edit' do
  end

  describe '#show' do

    it "succeeds when the role exists" do
      get :show, :id => a_role.id
      response.should be_success
    end

    it "finds the right role" do
      get :show, :id => a_role.id
      response.decoded_body.id.should == a_role.id
      response.decoded_body.name.should == a_role.name
      response.decoded_body.description.should == a_role.description
    end

    it "fails when the role doesn't exist" do
      get :show, :id => 'garbage_id'
      response.should be_not_found
    end
  end

  describe '#update' do
    let (:old_params ){
      {
          :id => a_role.id,
          :name => a_role.name,
          :description => a_role.description
      }
    }

    let (:new_params) {
      {
          :name => 'different name',
          :description => 'different description'
      }
    }

    it "updates the correct attributes" do
      put :update, old_params.merge(:role => new_params)
      response.decoded_body.name.should == new_params[:name]
      response.decoded_body.description.should == new_params[:description]
    end
  end

  describe '#destroy' do
    let (:new_role) { FactoryGirl.create(:role, :name => "destory me!") }

    it "destroys the role given the proepr id" do
      old_count = Role.count
      new_role

      Role.count.should == old_count + 1
      delete :destroy, { :id => new_role.id }
      Role.count.should == old_count
    end
  end
end
