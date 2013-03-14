require 'spec_helper'

describe ImportManager do
  let(:import_manager) { ImportManager.new(import) }

  describe "#schema_or_workspace_with_deleted" do
    context "with a workspace_import" do
      let(:import) { imports(:one) }

      it "returns workspace_with_deleted" do
        import_manager.schema_or_workspace_with_deleted.should == import.workspace_with_deleted
      end
    end

    context "with a schema import" do
      let(:import) { imports(:oracle) }

      it "returns the schema" do
        import_manager.schema_or_workspace_with_deleted.should == import.schema
      end
    end
  end

  describe "#schema_or_sandbox" do
    context "with a workspace_import" do
      let(:import) { imports(:one) }

      it "returns the workspace sandbox" do
        import_manager.schema_or_sandbox.should == import.workspace_with_deleted.sandbox
      end
    end

    context "with a schema import" do
      let(:import) { imports(:oracle) }

      it "returns the schema" do
        import_manager.schema_or_sandbox.should == import.schema
      end
    end
  end
end