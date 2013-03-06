require 'spec_helper'

describe DatasetStreamer do
  let(:dataset) { datasets(:table) }
  let(:user) { users(:owner) }
  let(:limit) { nil }
  let(:options) { { row_limit: limit, target_is_greenplum: true } }
  let(:streamer) { DatasetStreamer.new(dataset, user, options) }

  describe "initialize" do
    let(:limit) { 8 }

    it "sets the options" do
      streamer.row_limit.should == 8
      streamer.target_is_greenplum.should be_true
    end
  end

  describe "sql" do
    it "returns the all_rows_sql for the dataset" do
      streamer.sql.should == dataset.all_rows_sql
    end

    context "when limit is set" do
      let(:limit) { 50 }
      it "adds the correct limit to the sql" do
        streamer.sql.should == dataset.all_rows_sql(limit)
      end
    end
  end

  describe "oracle integration", :oracle_integration do
    let(:schema) { OracleIntegration.real_schema }
    let(:table) { schema.datasets.find_by_name('ALL_COLUMN_TABLE') }
    let(:view) { schema.datasets.find_by_name('ALL_COLUMN_VIEW') }
    let(:user) { OracleIntegration.real_data_source.owner }
    let(:table_streamer) { DatasetStreamer.new(table, user, options) }
    let(:view_streamer) { DatasetStreamer.new(view, user, options) }

    it "generates the same result for a table and an identical view" do
      table_streamer.enum.to_a.should == view_streamer.enum.to_a
    end
  end
end
