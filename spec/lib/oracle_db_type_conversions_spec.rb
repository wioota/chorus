require 'spec_helper'
require 'oracle_db_type_conversions'

describe "OracleDbTypeConversions" do
  describe "#type_category" do
    before do
      class TestFubar
        include OracleDbTypeConversions
      end
    end

    def self.it_has_type_category(type, category, greenplum_type=nil)
      context "with a '#{type}' column" do
        it "has the #{category} category" do
          TestFubar.new.to_category(type).should == category
        end

        unless greenplum_type.nil?
          it "has the #{greenplum_type} greenplum type" do
            TestFubar.new.convert_column_type(type).should == greenplum_type
          end
        end
      end
    end

    it_has_type_category("BFILE", "OTHER")
    it_has_type_category("BINARY_DOUBLE", "REAL_NUMBER", "float8")
    it_has_type_category("BINARY_FLOAT", "REAL_NUMBER", "float8")
    it_has_type_category("BLOB", "OTHER")
    it_has_type_category("CHAR", "STRING", "character")
    it_has_type_category("CLOB", "LONG_STRING", "text")
    it_has_type_category("DATE", "DATETIME", "timestamp")
    it_has_type_category("DECIMAL", "REAL_NUMBER", "float8")
    it_has_type_category("INT", "WHOLE_NUMBER", "numeric")
    it_has_type_category("LONG", "LONG_STRING")
    it_has_type_category("LONG RAW", "OTHER")
    it_has_type_category("MLSLABEL", "OTHER")
    it_has_type_category("NCHAR", "STRING", "character")
    it_has_type_category("NCLOB", "LONG_STRING", "text")
    it_has_type_category("NUMBER", "WHOLE_NUMBER", "numeric")
    it_has_type_category("NVARCHAR2", "STRING", "character varying")
    it_has_type_category("RAW", "OTHER")
    it_has_type_category("ROWID", "LONG_STRING", "text")
    it_has_type_category("TIMESTAMP", "DATETIME", "timestamp")
    it_has_type_category("UROWID", "LONG_STRING", "text")
    it_has_type_category("VARCHAR", "STRING", "character varying")
    it_has_type_category("VARCHAR2", "STRING", "character varying")
    it_has_type_category("XMLTYPE", "OTHER")
    it_has_type_category("TIMESTAMP WITH TIME ZONE", "DATETIME", "TIMESTAMP with timezone")
    it_has_type_category("TIMESTAMP WITHOUT TIME ZONE", "DATETIME", "TIMESTAMP without timezone")
    it_has_type_category("TIMESTAMP(6)", "DATETIME", "timestamp")
  end
end