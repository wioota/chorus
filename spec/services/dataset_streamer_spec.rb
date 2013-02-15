require 'spec_helper'

describe DatasetStreamer do
  let(:dataset) { datasets(:table) }
  let(:user) { users(:owner) }
  let(:limit) { nil }
  let(:streamer) { DatasetStreamer.new(dataset, user, limit) }

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