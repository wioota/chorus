require 'spec_helper'

describe OracleSqlResult do
  let(:result) { OracleSqlResult.new(result_set: fake_result_set) }
  let(:supported) { OracleDbTypeConversions::GREENPLUM_TYPE_MAP.keys }
  let(:unsupported) { OracleDbTypeConversions::CATEGORY_MAP.keys - supported }
  let(:fake_meta_data) { Object.new }
  let(:fake_result_set) { Object.new }
  let(:enum) { [true, false].each }

  describe "string values for columns" do
    before do
      stub(fake_result_set).get_string(anything) { "data_string" }
      stub(fake_result_set).meta_data { fake_meta_data }
      stub(fake_result_set).next { enum.next }

      stub(fake_meta_data).column_count { column_data_types.count }
      stub(fake_meta_data).column_type_name(anything) do |index|
        column_data_types[index-1]
      end
      stub(fake_meta_data).get_column_name(anything) do |index|
        "COLUMN_#{index}"
      end
    end

    context "when getting a supported data type" do
      let(:column_data_types) { supported }

      it "returns the value as a string" do
        result.rows.first.should == %w(data_string) * column_data_types.count
      end
    end

    context "when getting an unsupported data type" do
      let(:column_data_types) { unsupported }

      before do
        stub(fake_meta_data).column_type_name(anything) { "COLUMN_TYPE" }
      end

      it "returns the column type" do
        result.rows.first.should == %w(column_type) * column_data_types.count
      end
    end
  end
end
