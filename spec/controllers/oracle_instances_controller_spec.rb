require 'spec_helper'

describe OracleInstancesController do
  ignore_authorization!

  let(:user) { users(:owner) }
  let(:instance_params) { {
      :name => 'New Instance',
      :maintenance_db => 'database',
      :host => 'oracle.com',
      :port => '123'
    }}

  before do
    log_in user
  end

  describe "#create" do
    it 'creates a new instance' do
      expect {
        post :create, instance_params
      }.to change(OracleInstance, :count).by(1)
      response.code.should == "201"
    end

    it 'presents the instance' do
      mock_present do |instance|
        instance.name == instance_params[:name]
      end
      post :create, instance_params
      response.should be_success
    end
  end
end
