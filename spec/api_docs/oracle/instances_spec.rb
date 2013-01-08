require 'spec_helper'

resource "Oracle DB: instances" do
  let(:owner) { users(:owner) }

  before do
    log_in owner
  end

  post "/oracle_instances" do
    example_request "Register a Oracle instance" do
      status.should == 201
    end
  end
end
