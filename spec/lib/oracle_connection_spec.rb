require 'spec_helper'

describe OracleConnection do
  let(:connection) { OracleConnection.new(
      :host => "chorus-oracle",
      :username => "system",
      :password => "oracle",
      :port => 1521,
      :database => "orcl"
  ) }
  describe "#connect!" do
    it "should connect" do
      mock.proxy(Sequel).connect("jdbc:oracle:thin:system/oracle@//chorus-oracle:1521/orcl", :test => true)

      connection.connect!
      connection.connected?.should be_true
    end
  end

  describe "#disconnect" do
    before do
      mock_conn = Object.new

      mock(Sequel).connect(anything, anything) { mock_conn }
      mock(mock_conn).disconnect
      connection.connect!
    end

    it "disconnects Sequel connection" do
      connection.should be_connected
      connection.disconnect
      connection.should_not be_connected
    end
  end
end