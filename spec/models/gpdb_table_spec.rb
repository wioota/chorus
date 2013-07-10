require "spec_helper"

describe GpdbTable do
  let(:table) { datasets(:table) }
  let(:account) { table.data_source.owner_account }
  let(:user) { table.data_source.owner }
  let(:connection) { Object.new }

  before do
    stub(table.schema).connect_with(account) { connection }
    stub(table.schema.parent).connect_with(account) { connection }
  end

  describe "#analyze" do
    it "calls out to the connection" do
      mock(connection).analyze_table(table.name)
      table.analyze(account)
    end
  end

  describe '#verify_in_source' do
    it 'is true if the table & schema exist in greenplum' do
      stub(connection).schema_exists?(table.schema.name) { true }
      stub(connection).table_exists?(table.name) { true }
      table.verify_in_source(user).should be_true
    end

    it 'is false if the table or schema do not exist in greenplum' do
      stub(connection).schema_exists?(table.schema.name) { true }
      stub(connection).table_exists?(table.name) { false }
      table.verify_in_source(user).should be_false

      stub(connection).schema_exists?(table.schema.name) { false }
      stub(connection).table_exists?(table.name) { true }
      table.verify_in_source(user).should be_false

      stub(connection).schema_exists?(table.schema.name) { false }
      stub(connection).table_exists?(table.name) { false }
      table.verify_in_source(user).should be_false
    end
  end
end
