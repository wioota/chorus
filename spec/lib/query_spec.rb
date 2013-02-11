require 'spec_helper'

describe GreenplumConnection::Query, :greenplum_integration do
  let(:account) { InstanceIntegration.real_gpdb_account }
  let(:database) { GpdbDatabase.find_by_name_and_data_source_id(InstanceIntegration.database_name, InstanceIntegration.real_gpdb_data_source) }
  let(:schema) { database.schemas.find_by_name('test_schema') }

  subject do
    GreenplumConnection::Query.new(schema.name, table)
  end

  let(:rows) do
    schema.connect_with(account).fetch(sql)
  end

  describe "queries" do
    context "when table is not in 'public' schema" do
      let(:sql) { "SELECT * FROM base_table1" }

      it "works" do
        lambda { rows }.should_not raise_error
      end
    end

    context "when 'public' schema does not exist" do
      let(:database_name) { "#{InstanceIntegration.database_name}_priv" }
      let(:database) { GpdbDatabase.find_by_name_and_data_source_id(database_name, InstanceIntegration.real_gpdb_data_source) }
      let(:schema) { database.schemas.find_by_name('non_public_schema') }
      let(:sql) { "SELECT * FROM non_public_base_table1" }

      it "works" do
        lambda { rows }.should_not raise_error
      end
    end
  end

  describe "#metadata_query" do
    context "Base table" do
      let(:table) { 'base_table1' }
      let(:sql) { subject.metadata_query.to_sql }

      it "returns a query whose result for a base table is correct" do
        row = rows.first

        row[:name].should == "base_table1"
        row[:description].should == "comment on base_table1"
        row[:definition].should be_nil
        row[:column_count].should == 5
        row[:row_count].should == 9
        row[:table_type].should == "BASE_TABLE"
        row[:last_analyzed].should_not be_nil
        row[:disk_size].to_i.should > 0
        row[:partition_count].should == 0
      end
    end

    context "Master table" do
      let(:table) { 'master_table1' }
      let(:sql) { subject.metadata_query.to_sql }

      it "returns a query whose result for a master table is correct" do
        row = rows.first

        row[:name].should == 'master_table1'
        row[:description].should == 'comment on master_table1'
        row[:definition].should be_nil
        row[:column_count].should == 2
        row[:row_count].should == 0 # will always be zero for a master table
        row[:table_type].should == 'MASTER_TABLE'
        row[:last_analyzed].should_not be_nil
        row[:disk_size].should == '0'
        row[:partition_count].should == 7
      end
    end

    context "External table" do
      let(:table) { 'external_web_table1' }
      let(:sql) { subject.metadata_query.to_sql }

      it "returns a query whose result for an external table is correct" do
        row = rows.first

        row[:name].should == 'external_web_table1'
        row[:description].should be_nil
        row[:definition].should be_nil
        row[:column_count].should == 5
        row[:row_count].should == 0 # will always be zero for an external table
        row[:table_type].should == 'EXT_TABLE'
        row[:last_analyzed].should_not be_nil
        row[:disk_size].should == '0'
        row[:partition_count].should == 0
      end
    end

    context "View" do
      let(:table) { 'view1' }
      let(:sql) { subject.metadata_query.to_sql }

      it "returns a query whose result for a view is correct" do
        row = rows.first
        row[:name].should == 'view1'
        row[:description].should == "comment on view1"
        row[:definition].should == "SELECT base_table1.id, base_table1.column1, base_table1.column2, base_table1.category, base_table1.time_value FROM base_table1;"
        row[:column_count].should == 5
        row[:row_count].should == 0
        row[:disk_size].should == '0'
        row[:partition_count].should == 0
      end
    end
  end
end