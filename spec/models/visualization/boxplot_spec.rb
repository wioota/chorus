require 'spec_helper'

describe Visualization::Boxplot, :greenplum_integration do
  before do
    set_current_user users(:default)
  end

  let(:account) { GreenplumIntegration.real_account }
  let(:database) { GpdbDatabase.find_by_name_and_data_source_id(GreenplumIntegration.database_name, GreenplumIntegration.real_data_source) }
  let(:dataset) { database.find_dataset_in_schema('base_table1', 'test_schema') }
  let(:bucket_count) { 20 }

  let(:visualization) do
    Visualization::Boxplot.new(dataset, {
        :x_axis => x_axis,
        :y_axis => y_axis,
        :bins => bucket_count,
        :filters => filters
    })
  end

  let(:x_axis) { "category" }
  let(:y_axis) { "column2" }

  describe "#fetch!" do
    let(:filters) { nil }

    context "dataset is a table" do
      it "returns the boxplot data" do
        visualization.fetch!(account, 12345)
        visualization.rows.should == [
            {:bucket => "papaya", :min => 5.0, :median => 6.5, :max => 8.0, :first_quartile => 5.5, :third_quartile => 7.5, :percentage => "44.44%", :count => 4},
            {:bucket => "orange", :min => 2.0, :median => 3.0, :max => 4.0, :first_quartile => 2.5, :third_quartile => 3.5, :percentage => "33.33%", :count => 3},
            {:bucket => "apple", :min => 0.0, :median => 0.5, :max => 1.0, :first_quartile => 0.25, :third_quartile => 0.75, :percentage => "22.22%", :count => 2}
        ]
      end

      it "limits the number of buckets in the boxplot summary" do
        mock(BoxplotSummary).summarize(anything, bucket_count)
        visualization.fetch!(account, 12345)
      end

      context "with filters" do
        let(:filters) { ["category != 'apple'"] }

        it "returns the boxplot data based on the filtered dataset" do
          visualization.fetch!(account, 12345)
          visualization.rows.should == [
              {:bucket => "papaya", :min => 5.0, :median => 6.5, :max => 8.0, :first_quartile => 5.5, :third_quartile => 7.5, :percentage => "57.14%", :count => 4},
              {:bucket => "orange", :min => 2.0, :median => 3.0, :max => 4.0, :first_quartile => 2.5, :third_quartile => 3.5, :percentage => "42.86%", :count => 3}
          ]
        end
      end

      context "with allcaps column names" do
        let(:dataset) { database.find_dataset_in_schema('allcaps_candy', 'test_schema') }
        let(:filters) { nil }
        let(:x_axis) { "KITKAT" }
        let(:y_axis) { "STUFF" }

        it "fetches the rows correctly" do
          visualization.fetch!(account, 12345)
          visualization.rows.should_not be_nil
        end
      end

      context "with null values" do
        let(:dataset) { database.find_dataset_in_schema('table_with_nulls', 'test_schema') }
        let(:filters) { ["category != 'banana'"] }
        let(:x_axis) { "category" }
        let(:y_axis) { "some_nulls" }

        it "does not count the nulls in the boxplot data" do
          visualization.fetch!(account, 12345)
          visualization.rows.should =~ [
              {:bucket => "orange", :min => 1.0, :median => 2.5, :max => 7.0, :first_quartile => 1.5, :third_quartile => 5.0, :percentage => "57.14%", :count => 4},
              {:bucket => "apple", :min =>5.0, :median => 7.0, :max => 14.0, :first_quartile => 6.0, :third_quartile => 10.5, :percentage => "42.86%", :count => 3}
          ]
        end

        context "with all null values" do
          let(:y_axis) { "all_nulls" }

          it "returns an empty set of rows" do
            visualization.fetch!(account, 12345)
            visualization.rows.should =~ []
          end
        end
      end

      context "when the category and the value are the same column" do
        let(:x_axis) { "column1" }
        let(:y_axis) { "column1" }

        it "raises an exception" do
          expect {
            visualization.fetch!(account, 12345)
          }.to raise_error
        end
      end
    end

    context "dataset is a chorus view" do
      let(:dataset) { datasets(:executable_chorus_view) }

      it "returns the boxplot data" do
        visualization.fetch!(account, 12345)
        visualization.rows.should == [
            {:bucket => "papaya", :min => 5.0, :median => 6.5, :max => 8.0, :first_quartile => 5.5, :third_quartile => 7.5, :percentage => "44.44%", :count => 4},
            {:bucket => "orange", :min => 2.0, :median => 3.0, :max => 4.0, :first_quartile => 2.5, :third_quartile => 3.5, :percentage => "33.33%", :count => 3},
            {:bucket => "apple", :min => 0.0, :median => 0.5, :max => 1.0, :first_quartile => 0.25, :third_quartile => 0.75, :percentage => "22.22%", :count => 2}
        ]
      end

      context "with filters" do
        let(:filters) { ["category != 'apple'"] }

        it "returns the boxplot data based on the filtered dataset" do
          visualization.fetch!(account, 12345)
          visualization.rows.should == [
              {:bucket => "papaya", :min => 5.0, :median => 6.5, :max => 8.0, :first_quartile => 5.5, :third_quartile => 7.5, :percentage => "57.14%", :count => 4},
              {:bucket => "orange", :min => 2.0, :median => 3.0, :max => 4.0, :first_quartile => 2.5, :third_quartile => 3.5, :percentage => "42.86%", :count => 3}
          ]
        end
      end
    end
  end
end