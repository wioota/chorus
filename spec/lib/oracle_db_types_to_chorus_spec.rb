require 'spec_helper'
require 'oracle_db_types_to_chorus'

describe "OracleDbTypesToChorus" do
  describe "#type_category" do
    before do
      class TestFubar
        include OracleDbTypesToChorus
      end
    end

    def self.it_has_type_category(type, category)
      context "with a '#{type}' column" do
        it "has the #{category} category" do
          TestFubar.new.to_category(type).should == category
        end
      end
    end

    it_has_type_category("BFILE", "OTHER")
    it_has_type_category("BINARY_DOUBLE", "REAL_NUMBER")
    it_has_type_category("BINARY_FLOAT", "REAL_NUMBER")
    it_has_type_category("BLOB", "OTHER")
    it_has_type_category("CHAR", "STRING")
    it_has_type_category("CLOB", "LONG_STRING")
    it_has_type_category("DATE", "DATE")
    it_has_type_category("DECIMAL", "REAL_NUMBER")
    it_has_type_category("INT", "WHOLE_NUMBER")
    it_has_type_category("LONG", "LONG_STRING")
    it_has_type_category("LONG RAW", "OTHER")
    it_has_type_category("MLSLABEL", "OTHER")
    it_has_type_category("NCHAR", "STRING")
    it_has_type_category("NCLOB", "LONG_STRING")
    it_has_type_category("NUMBER", "WHOLE_NUMBER")
    it_has_type_category("NVARCHAR2", "STRING")
    it_has_type_category("RAW", "OTHER")
    it_has_type_category("ROWID", "LONG_STRING")
    it_has_type_category("TIMESTAMP", "DATE")
    it_has_type_category("UROWID", "LONG_STRING")
    it_has_type_category("VARCHAR", "STRING")
    it_has_type_category("VARCHAR2", "STRING")
    it_has_type_category("XMLTYPE", "OTHER")
    it_has_type_category("TIMESTAMP WITH TIME ZONE", "DATETIME")
    it_has_type_category("TIMESTAMP WITHOUT TIME ZONE", "DATETIME")
  end
end