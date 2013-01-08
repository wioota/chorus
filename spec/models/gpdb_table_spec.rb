require "spec_helper"

describe GpdbTable do
  let(:table) { datasets(:table) }
  let(:account) { table.gpdb_instance.owner_account }
  let(:connection) { Object.new }

  before do
    stub(table.schema).connect_with(account) { connection }
  end

  describe "#analyze" do
    it "calls out to the connection" do
      mock(connection).analyze_table(table.name)
      table.analyze(account)
    end
  end
end
