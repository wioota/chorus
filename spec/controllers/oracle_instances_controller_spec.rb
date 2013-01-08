require 'spec_helper'

describe OracleInstancesController do
  ignore_authorization!

  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe "#create" do
      it "reports that the gpdb instance was created" do
        post :create
        response.code.should == "201"
      end
  end
end
