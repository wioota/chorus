require 'spec_helper'

describe GnipDataSourceImportsController do
  let(:user) { users(:owner) }
  let(:gnip_data_source) { gnip_data_sources(:default) }
  let(:workspace) { workspaces(:public) }

  let(:gnip_data_source_import_params) { {
      :gnip_data_source_id => gnip_data_source.id,
      :import => {
          :to_table => 'foobar',
          :workspace_id => workspace.id
      }
  } }

  describe "#create" do
    before do
      log_in user
    end

    it "uses authentication" do
      mock(subject).authorize! :can_edit_sub_objects, workspace
      post :create, gnip_data_source_import_params
    end

    context "when the import is created successfully" do
      before do
        mock(GnipImport).create!.with_any_args { true }
      end

      it "presents an empty array" do
        mock_present { |model| model.should == [] }
        post :create, params
      end
    end
  end
end
