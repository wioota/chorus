require 'spec_helper'

resource "Greenplum DB: datasets" do
  let(:owner) { gpdb_table.schema.gpdb_instance.owner }
  let(:gpdb_table) { datasets(:table) }
  let(:dataset_id) { gpdb_table.to_param }
  let!(:owner_account) { gpdb_table.schema.gpdb_instance.account_for_user(owner) }
  let(:row) {
    { "definition" => "definition",
      "description" => "description",
      "row_count" => "6999",
      "column_count" => "5",
      "table_type" => 'MASTER_TABLE',
      "disk_size" => '350 megabytes',
      "last_analyzed" => "2012-07-20 09:57:52.44482-07",
      "partition_count" => "366" }
  }

  let(:stats) do
    DatasetStatistics.new(row)
  end

  before do
    any_instance_of(GpdbTable) do |gpdb_table|
      stub(gpdb_table).add_metadata!(owner_account) { stats }
    end

    log_in owner
  end

  get "/datasets/:dataset_id/statistics" do
    parameter :dataset_id, "Table ID"
    required_parameters :dataset_id

    example_request "Retrieve table statistics" do
      status.should == 200
    end
  end
end