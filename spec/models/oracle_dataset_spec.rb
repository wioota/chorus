require 'spec_helper'

describe OracleDataset do
  let(:dataset) { datasets(:oracle_table) }

  describe "#all_rows_sql" do
    let(:schema) { OracleSchema.new(:name => "foobar")}
    let(:dataset) { OracleTable.new(:name => "table_name") }

    before { dataset.schema = schema }

    it "specifies the schema" do
      dataset.all_rows_sql.should == "SELECT * FROM \"foobar\".\"table_name\""
    end

    it "specifies the limit" do
      dataset.all_rows_sql(5).should =~ /WHERE rownum <= 5/i
    end
  end

  describe '#instance_account_ids' do
    it 'returns instance account ids with access to the schema' do
      dataset.instance_account_ids.should == dataset.schema.instance_account_ids
    end
  end
end