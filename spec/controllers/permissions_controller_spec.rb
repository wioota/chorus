require 'spec_helper'

describe PermissionsController do
  let(:user) { users(:owner) }
  let (:a_permission) { permissions(:a_permission) }

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

    it "returns a list of permissions" do
      response.decoded_body.length.should == Permission.count
    end
  end

  describe '#create' do
    let (:a_role) { roles(:a_role) }
    let (:a_chorus_class) { ChorusClass.create(:name => "TempClass") }
    let (:params) {
      {
          :role_id => a_role.id,
          :chorus_class_id => a_chorus_class.id,
          :permissions_mask => 1
      }
    }

    it_behaves_like "an action that requires authentication", :post, :create

    it "should create a permission" do
      old_count = Permission.count
      post :create, { :permission => params }
      Permission.count.should == old_count + 1
    end
  end

  describe '#new' do
  end

  describe '#edit' do
  end

  describe '#show' do

    it "succeeds when the permission exists" do
      get :show, :id => a_permission.id
      response.should be_success
    end

    it "finds the right permission" do
      get :show, :id => a_permission.id
      response.decoded_body.id.should == a_permission.id
      response.decoded_body.chorus_class_id.should == a_permission.chorus_class_id
      response.decoded_body.permissions_mask.should == a_permission.permissions_mask
    end

    it "fails when the role doesn't exist" do
      get :show, :id => 'garbage_id'
      response.should be_not_found
    end
  end

  describe '#update' do
    let (:old_params ){
      {
          :id => a_permission.id,
          :chorus_class_id => a_permission.chorus_class_id,
          :permissions_mask => a_permission.permissions_mask
      }
    }

    let (:a_different_chorus_class) { ChorusClass.create(:name => "NewClass") }

    let (:new_params) {
      {
          :chorus_class_id => a_different_chorus_class.id,
          :permissions_mask => 10
      }
    }

    it "updates the correct attributes" do
      put :update, old_params.merge(:permission => new_params)
      response.decoded_body.chorus_class_id.should == new_params[:chorus_class_id]
      response.decoded_body.permissions_mask.should == new_params[:permissions_mask]
    end
  end

  describe '#destroy' do
    let (:new_permission) { FactoryGirl.create(:permission, :chorus_class_id => "666") }

    it "destroys the role given the proepr id" do
      old_count = Permission.count
      new_permission

      Permission.count.should == old_count + 1
      delete :destroy, { :id => new_permission.id }
      Permission.count.should == old_count
    end
  end
end
