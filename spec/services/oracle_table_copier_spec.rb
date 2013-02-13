require 'spec_helper'

describe OracleTableCopier, :oracle_integration do
  let(:source_schema) { OracleIntegration.real_schema }
  let(:source_table_name) { 'ALL_COLUMN_TABLE' }
  let(:source_table) { source_schema.datasets.find_by_name(source_table_name) }
  let(:source_url) { source_schema.connect_as(source_schema.data_source.owner).db_url }
  let(:dest_url) { "" }
  let(:attributes) do
    {
        :from_table => source_table.as_sequel
    }
  end
  let(:copier) { OracleTableCopier.new(source_url, dest_url, attributes) }

  describe "#table_definition" do
    it "should do the right thing" do
      columns = [
          %Q{"BIN_DOUBLE" float8},
          %Q{"BIN_FLOAT" float8},
          %Q{"CHARACTER" character},
          %Q{"CHAR_BLOB" text},
          %Q{"DAY" timestamp},
          %Q{"DECIMAL_COL" numeric},
          %Q{"INTEGER_COL" numeric},
          %Q{"LONG_COL" text},
          %Q{"NUMBER_COL" numeric},
          %Q{"ROW_ID" text},
          %Q{"TIMESTAMP_COL" timestamp},
          %Q{"UNICODE_CHAR" character},
          %Q{"UNICODE_CLOB" text},
          %Q{"UNICODE_VARCHAR" character varying},
          %Q{"UNIVERSAL_ROW_ID" text},
          %Q{"VARIABLE_CHARACTER" character varying},
          %Q{"VARIABLE_CHARACTER_2" character varying},
      ]
      copier.table_definition.should == columns.join(', ')
    end
  end

  describe "#primary_key_clause" do
    subject { copier.primary_key_clause }

    context "when the table has no primary key" do
      let(:source_table_name) { "NEWERTABLE" }

      it { should == '' }
    end

    context "when the table has a primary key" do
      let(:source_table_name) { "WITH_COMPOSITE_KEY" }

      it { should == ", PRIMARY KEY(\"COLUMN2\", \"COLUMN1\")" }
     end
  end

  describe "#distribution_key_clause" do
    subject { copier.distribution_key_clause }

    context "when the table has no primary key" do
      let(:source_table_name) { "NEWERTABLE" }

      it { should == 'DISTRIBUTED RANDOMLY' }
    end

    context "when the table has a primary key" do
      let(:source_table_name) { "WITH_COMPOSITE_KEY" }

      it { should == "DISTRIBUTED BY(\"COLUMN2\", \"COLUMN1\")" }
    end
  end
end