require 'spec_helper'

describe Visualization::Timeseries, :greenplum_integration do
  let(:account) { GreenplumIntegration.real_account }
  let(:filters) { [%Q{"#{dataset.name}"."time_value" > '2012-03-03'},
                   %Q{"#{dataset.name}"."column1" < 5}] }

  let(:visualization) do
    Visualization::Timeseries.new(dataset, {
        :time_interval => "month",
        :aggregation => "sum",
        :x_axis => "time_value",
        :y_axis => "column1",
        :filters => filters
    })
  end

  context "blah" do
    let(:test_schema) { GreenplumIntegration.real_database.schemas.find_by_name('test_schema') }
    let(:filters) { [] }
    let(:dataset) {
      d = datasets(:executable_chorus_view)
      d.update_attribute(:query, "select g as column1, (NOW() + '1 month'::INTERVAL * g) as time_value from (select generate_series(1,2000) as g) a;")
      d
    }

    it "raises an error" do
      expect {
        visualization.fetch!(account, 12345)
      }.to raise_error(ApiValidationError)
    end
  end

  describe "#fetch!" do
    before do
      visualization.fetch!(account, 12345)
    end

    context "with a table" do
      let(:database) { GreenplumIntegration.real_database }
      let(:dataset) { database.find_dataset_in_schema('base_table1', 'test_schema') }

      context "with no filter" do
        let(:filters) { nil }

        it "returns the timeseries data" do
          visualization.rows.should == [
              {:value => 3, :time => '2012-03'},
              {:value => 2, :time => '2012-04'},
              {:value => 1, :time => "2012-05"}
          ]
        end
      end

      context "with filters" do
        it "returns the timeseries data based on the filtered dataset" do
          visualization.rows.should == [
              {:value => 2, :time => "2012-03"},
              {:value => 2, :time => "2012-04"},
              {:value => 1, :time => "2012-05"}
          ]
        end
      end
    end

    context "with a chorus view" do
      let(:dataset) { datasets(:executable_chorus_view) }

      context "with no filter" do
        let(:filters) { nil }

        it "returns the timeseries data" do
          visualization.rows.should == [
              {:value => 3, :time => '2012-03'},
              {:value => 2, :time => '2012-04'},
              {:value => 1, :time => "2012-05"}
          ]
        end
      end

      context "with filters" do
        it "returns the timeseries data based on the filtered dataset" do
          visualization.rows.should == [
              {:value => 2, :time => "2012-03"},
              {:value => 2, :time => "2012-04"},
              {:value => 1, :time => "2012-05"}
          ]
        end
      end
    end
  end
end