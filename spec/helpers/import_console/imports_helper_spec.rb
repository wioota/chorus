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
end