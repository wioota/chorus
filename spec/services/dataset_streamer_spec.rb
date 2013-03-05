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
end
