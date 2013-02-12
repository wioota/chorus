require 'spec_helper'

resource "OracleImports" do
  let(:user) { users(:owner) }
  let(:executor) { Object.new }

  before do
    log_in user

    stub(OracleImportExecutor).new { executor }
    stub(executor).run
  end

  post "/oracle_imports" do
    parameter :schema_id, "The id of the Greenplum schema to import into"
    parameter :table_name, "The name of the destination table"

    required_parameters :schema_id, :table_name

    let(:table_name) { "foo" }
    let(:schema_id) { GreenplumIntegration.real_database.schemas.find_by_name('test_schema').id }

    example_request "Create an Oracle Import" do
      status.should == 201
    end
  end
end