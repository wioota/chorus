require 'spec_helper'

describe OracleConnection, :oracle_integration do
  before(:all) do
    require Rails.root + 'lib/libraries/ojdbc6.jar'
  end

  let(:connection) { OracleConnection.new(
      :host => "chorus-oracle",
      :username => "system",
      :password => "oracle",
      :port => 8888,
      :database => "orcl"
  ) }
  describe "#connect!" do
    it "should connect" do
      mock(Sequel).connect("jdbc:oracle:thin:system/oracle@//chorus-oracle:8888/orcl", :test => true) { true }

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

  describe "OracleConnection::DatabaseError" do
    let(:sequel_exception) {
      obj = Object.new
      wrp_exp = Object.new
      stub(obj).wrapped_exception { wrp_exp }
      stub(obj).message { "A message" }
      obj
    }

    let(:error) do
      OracleConnection::DatabaseError.new(sequel_exception)
    end

    describe "error_type" do
      context "when the wrapped error has an error code" do
        before do
          stub(sequel_exception.wrapped_exception).get_error_code { error_code }
        end

        context "when the error code is 12514" do
          let(:error_code) { 12514}

          it "returns :DATABASE_MISSING" do
            error.error_type.should == :DATABASE_MISSING
          end
        end

        context "when the error code is 1017" do
          let(:error_code) { 1017 }

          it "returns :INVALID_PASSWORD" do
            error.error_type.should == :INVALID_PASSWORD
          end
        end

        context "when the error code is 17002" do
          let(:error_code) { 17002 }

          it "returns :INSTANCE_UNREACHABLE" do
            error.error_type.should == :INSTANCE_UNREACHABLE
          end
        end
      end

      context "when the wrapped error has no sql state error code" do
        it "returns :GENERIC" do
          error.error_type.should == :GENERIC
        end
      end
    end

    describe "sanitizing exception messages" do
      let(:error) { OracleConnection::DatabaseError.new(StandardError.new(message)) }

      let(:message) do
        "foo jdbc:oracle:thin:system/oracle@//chorus-oracle:8888/orcl and stuff"
      end

      it "should sanitize the connection string" do
        error.message.should == "foo jdbc:oracle:thin:xxxx/xxxx@//chorus-oracle:8888/orcl and stuff"
      end
    end
  end
end