require 'spec_helper'

describe Schemas::ImportsController, :greenplum_integration => true, :oracle_integration => true, :type => :controller do
  let(:source_dataset) { OracleIntegration.real_schema.datasets.tables.first }
  let(:schema) { GreenplumIntegration.real_database.schemas.find_by_name("test_schema") }
  let(:user) { schema.data_source.owner }
  let(:to_table) { "the_new_table" }

  let(:attrs_for_schema) do
    {
        schema_id: schema.to_param,
        to_table: to_table,
        sample_count: "12",
        truncate: "false",
        dataset_id: source_dataset.to_param,
        new_table: 'true'
    }
  end

  before { log_in user }

  it 'creates a new import' do
    expect {
      post :create, attrs_for_schema
      response.code.should == "201"
    }.to change(SchemaImport, :count).by(1)
    import = SchemaImport.last

    import.schema.should == schema
    import.to_table.should == to_table
    import.source_dataset.should == source_dataset
    import.truncate.should == false
    import.user_id.should == user.id
    import.sample_count.should == 12
    import.new_table.should == true
  end
end