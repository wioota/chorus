require 'spec_helper'

describe ExternalStreamsController, :greenplum_integration => true, :type => :controller do
  let(:user) { users(:owner) }
  let(:dest_schema) { GreenplumIntegration.real_database.schemas.find_by_name('test_schema') }
  let(:dest_table_name) { "external_stream_functional_table" }

  let(:src_dataset) {
    schema = OracleIntegration.real_schema
    schema.datasets.find_by_name("NEWTABLE")
  }

  let(:expected_csv) {
    "1,row_1\n2,row_2\n3,row_3\n4,row_4\n"
  }

  before do
    import = dest_schema.imports.new(
        :to_table => dest_table_name,
        :truncate => "false",
    )

    import.source_dataset = src_dataset
    import.user = user
    import.stream_key = "12345"
    import.save!
  end

  after do
    dest_schema.connect_as(user).drop_table(dest_table_name)
  end

  it "streams the Source Dataset for an Import" do
    get :show, :stream_key => "12345", :row_limit => "4"
    response.body.should eq(expected_csv)
  end
end