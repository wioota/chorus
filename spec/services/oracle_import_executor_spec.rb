require 'spec_helper'

describe OracleImportExecutor do
  let(:user) { users(:admin) }
  let(:schema) { GreenplumIntegration.real_database.schemas.find_by_name('test_schema') }
  let(:table_name) { "foo" }
  let(:url) { "http://example.com/" }

  let(:columns) { "col1 int, col2 int, col3 int" }

  let(:params) { {
      :schema_id => schema.id,
      :table_name => table_name
  } }

  let(:valid_external_table_options) { {
      :location_url => url,
      :web => true,
      :columns => columns,
      :table_name => table_name + "_ext",
      :delimiter => ","
  } }

  let(:executor) {
    OracleImportExecutor.new(:schema => schema, :table_name => table_name, :user => user, :url => url)
  }

  let(:connection) {Object.new}

  describe "#run" do
    it "should create an external table in the given Gpdb schema" do
      mock(schema).connect_as(user) { connection }
      mock(connection).create_external_table(valid_external_table_options)
      executor.run
    end
  end
end