require 'spec_helper'

describe OracleDataset do
  let(:dataset) { datasets(:oracle_table) }

  describe "#all_rows_sql" do
    let(:schema) { OracleSchema.new(:name => "foobar")}
    let(:dataset) { OracleTable.new(:name => "table_name") }
    let(:dataset_columns) { [
        OracleDatasetColumn.new(:name => "unsupported",
                                :data_type => "MLSLABEL",
                                :ordinal_position => 1,
                                :description => "unsupported"
        ),
        OracleDatasetColumn.new(:name => "supported",
                                :data_type => "varchar",
                                :ordinal_position => 2,
                                :description => "supported")
    ] }

    before do
      dataset.schema = schema
      stub(dataset).column_data.returns(dataset_columns)
    end

    it "selects only the columns that are supported" do
      dataset.all_rows_sql.should == "SELECT 'mlslabel' AS \"unsupported\", \"supported\" FROM \"foobar\".\"table_name\""
    end
  end

  describe '#instance_account_ids' do
    it 'returns instance account ids with access to the schema' do
      dataset.instance_account_ids.should == dataset.schema.instance_account_ids
    end
  end
end