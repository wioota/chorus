require 'spec_helper'

describe OracleSqlResult do
  let(:result) { OracleSqlResult.new }
  let(:supported) { OracleDbTypeConversions::GREENPLUM_TYPE_MAP.keys }
  let(:unsupported) { OracleDbTypeConversions::CATEGORY_MAP.keys - supported }
  let(:fake_meta_data) { Object.new }
  let(:fake_result_set) { Object.new }

  describe "#column_string_value" do
    before do
      stub(fake_result_set).get_string(anything) do
        "data string"
      end
      stub(fake_meta_data).column_type_name(anything) do |index|
        column_data_types[index]
      end
    end

    context "when getting an supported data type" do
      let(:column_data_types) { supported }

      it "returns the value as a string" do
        (0...column_data_types.length).each do |index|
          result.column_string_value(fake_meta_data, fake_result_set, index).should == "data string"
        end
      end
    end

    context "when getting an unsupported data type" do
      let(:column_data_types) { unsupported }

      before do
        stub(fake_meta_data).column_type_name(anything) do
          "COLUMN_TYPE"
        end
      end

      it "returns the column name" do
        (0...column_data_types.length).each do |index|
          result.column_string_value(fake_meta_data, fake_result_set, index).should == "column_type"
        end
      end
    end
  end
end
