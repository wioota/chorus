require 'spec_helper'
require 'socket'

describe UsedPortsValidator do
  before do
    stub(UsedPortsValidator).log
  end

  describe '.run' do
    let (:ports_to_check) { [] }

    it "returns true if all required ports on system are not in use" do
      ports_to_check = []
      UsedPortsValidator.run(ports_to_check).should be_true
    end

    it "returns false if a required port is in use" do
     stub(TCPServer).new.with_any_args { |obj| raise Errno::EADDRINUSE }

      ports_to_check = [3000, 5432, 8080]
      UsedPortsValidator.run(ports_to_check).should be_false
    end
  end
end
