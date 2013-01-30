require 'spec_helper'

resource "OraclePipes" do
  let(:user) { users(:owner) }

  before do
    log_in user

    mock(OracleDatasetStreamer).new do
      obj = Object.new
      mock(obj).enum { "OK" }
      obj
    end
  end

  get "/oracle_pipes" do
    example_request "Get an oracle pipe" do
      status.should == 200
    end
  end
end