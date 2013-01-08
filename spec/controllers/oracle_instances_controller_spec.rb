require 'spec_helper'

describe OracleInstancesController do
  ignore_authorization!

  let(:user) { users(:owner) }
  let(:instance_params) { {
      :name => 'New Instance',
      :db_name => 'database',
      :host => 'oracle.com',
      :port => '123'
    }}

  before do
    log_in user
  end

  describe "#create" do
    before do
      mock.proxy(Oracle::InstanceRegistrar).create!(hash_including(instance_params), user)
    end

    it 'creates a new instance' do
      expect {
        post :create, instance_params
      }.to change(OracleInstance, :count).by(1)
      response.code.should == "201"
    end

    it 'presents the instance' do
      post :create, instance_params
      decoded_response.name.should == 'New Instance'
    end
  end
end
