require "spec_helper"

class DummyClass
  include ImportConsole::ImportsHelper
end

describe ImportConsole::ImportsHelper do
  describe "linking to tables" do
    let(:workspace) { workspaces(:public) }
    let(:dummy) { DummyClass.new }

    context "when the dataset is a chorus view" do
      let(:dataset) { datasets(:chorus_view) }

      it "includes chorus_views in the url" do
        dummy.link_to_table(workspace, dataset).should include("chorus_views")
      end
    end

    context "when the dataset is not a chorus view" do
      let(:dataset) { datasets(:table) }

      it "includes datasets in the url" do
        dummy.link_to_table(workspace, dataset).should include("datasets")
      end
    end
  end

  describe "#table_description" do
    context "when the schema belongs to a database" do
      it "returns a description consisting of database, schema and table name" do
        table_description(schemas(:default), "gpdb_table").should == "default.default.gpdb_table"
      end
    end

    context "when the schema belong to a database" do
      it "omits the database" do
        table_description(schemas(:oracle), "oracle_table").should == "oracle.oracle_table"
      end
    end
  end
end