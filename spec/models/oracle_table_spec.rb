require 'spec_helper'

describe OracleTable do
  describe "#verify_in_source" do
    let(:table) { datasets(:oracle_table) }
    let(:user) { users(:owner) }
    let(:connection) { Object.new }

    it "calls table_exists? on the oracle database connection" do
      stub(table.schema).connect_as(user) { connection }
      mock(connection).table_exists?(table.name) { "duck" }
      table.verify_in_source(user).should == "duck"
    end
  end
end