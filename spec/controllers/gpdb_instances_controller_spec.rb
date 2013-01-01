require 'spec_helper'

describe GpdbInstancesController do
  ignore_authorization!

  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe "#index" do
    it "returns all gpdb instances" do
      get :index
      response.code.should == "200"
      decoded_response.size.should == GpdbInstance.count
    end

    it_behaves_like "a paginated list"

    it "returns all gpdb instances (online and offline) that the user can access when accessible is passed" do
      get :index, :accessible => "true"
      response.code.should == "200"
      decoded_response.map(&:id).should include(gpdb_instances(:offline).id)
    end
  end

  describe "#show" do
    let(:gpdb_instance) { gpdb_instances(:owners) }

    context "with a valid instance id" do
      it "does not require authorization" do
        dont_allow(subject).authorize!.with_any_args
        get :show, :id => gpdb_instance.to_param
      end

      it "succeeds" do
        get :show, :id => gpdb_instance.to_param
        response.should be_success
      end

      it "presents the gpdb instance" do
        mock.proxy(controller).present(gpdb_instance)
        get :show, :id => gpdb_instance.to_param
      end

      generate_fixture "gpdbInstance.json" do
        get :show, :id => gpdb_instance.to_param
      end
    end

    context "with an invalid gpdb instance id" do
      it "returns not found" do
        get :show, :id => 'invalid'
        response.should be_not_found
      end
    end
  end

  describe "#update" do
    let(:changed_attributes) { {"name" => "changed"} }
    let(:gpdb_instance) { gpdb_instances(:shared) }
    let(:params) { changed_attributes.merge( :id => gpdb_instance.id) }

    before do
      stub(Gpdb::InstanceRegistrar).update!(gpdb_instance, changed_attributes, user) { gpdb_instance }
    end

    it "uses authorization" do
      mock(subject).authorize!(:edit, gpdb_instance)
      put :update, params
    end

    it "returns 200" do
      put :update, params
      response.code.should == "200"
    end

    it "returns 422 when the update parameters are invalid" do
      stub(Gpdb::InstanceRegistrar).update!(gpdb_instance, changed_attributes, user) do
        raise(ActiveRecord::RecordInvalid.new(gpdb_instance))
      end
      put :update, params
      response.code.should == "422"
    end
  end

  describe "#create" do
    it_behaves_like "an action that requires authentication", :put, :update, :id => '-1'

    context "with register provision type" do
      let(:valid_attributes) { Hash.new }
      let(:instance) { gpdb_instances(:default) }

      before do
        mock(Gpdb::InstanceRegistrar).create!(valid_attributes, user) { instance }
      end

      it "reports that the gpdb instance was created" do
        post :create, valid_attributes
        response.code.should == "201"
      end

      it "renders the newly created gpdb instance" do
        post :create, valid_attributes
        decoded_response.name.should == instance.name
      end

      it "schedules a job to refresh the instance" do
        mock(QC.default_queue).enqueue_if_not_queued("GpdbInstance.refresh", numeric, {'new' => true})
        post :create, :gpdb_instance => valid_attributes
      end
    end

    context "with invalid attributes" do
      before do
        stub(Gpdb::InstanceRegistrar).create!({}, user) {
          raise(ActiveRecord::RecordInvalid.new(gpdb_instances(:default)))
        }
      end

      it "responds with validation errors" do
        post :create
        response.code.should == "422"
      end
    end
  end
end
