require 'spec_helper'

describe WorkspaceDatasetsController do
  ignore_authorization!

  context "with stubbed greenplum" do
    let(:user) { users(:the_collaborator) }
    let(:workspace) { workspaces(:public) }
    let(:gpdb_view) { datasets(:view) }
    let(:gpdb_table) { datasets(:table) }
    let(:other_table) { datasets(:other_table) }
    let(:source_table) { datasets(:source_table) }
    let(:source_view) { datasets(:source_view) }
    let(:the_datasets) { fake_relation [gpdb_table, gpdb_view] }

    before do
      log_in user

      mock(Workspace).
          workspaces_for(user).mock!.
          find(workspace.to_param) { workspace }

      stub(workspace).datasets { the_datasets }
      stub(workspace).dataset_count { 42 }
      any_instance_of(GpdbTable) do |table|
        stub(table).accessible_to(user) { true }
        stub(table).verify_in_source
      end
      any_instance_of(GpdbView) do |view|
        stub(view).accessible_to(user) { true }
        stub(view).verify_in_source
      end
    end

    describe "#index" do
      it "uses authorization" do
        mock(subject).authorize! :show, workspace
        get :index, :workspace_id => workspace.to_param
      end

      it "presents the workspace's datasets, ordered by name and paginated" do
        mock_present { |collection|
          collection.to_a.to_a.should =~ the_datasets.to_a
        }

        get :index, :workspace_id => workspace.to_param
        response.should be_success
      end

      it "orders and paginates the datasets" do
        mock(the_datasets).order("lower(replace(datasets.name,'_',''))") { the_datasets }
        mock(the_datasets).paginate("page" => "2", "per_page" => "25", "total_entries" => 42) { the_datasets }
        get :index, :workspace_id => workspace.to_param, :page => "2", :per_page => "25"
      end

      it "passes the workspace to the presenter" do
        mock_present { |collection, _, options| options[:workspace].should be_true }
        get :index, :workspace_id => workspace.to_param
      end

      it "filter the list by the name_pattern value" do
        mock(workspace).dataset_count(is_a(User), hash_including(:name_filter => "view")) { 12 }
        mock(workspace).datasets(is_a(User), hash_including(:name_filter => "view")) { the_datasets }
        get :index, :workspace_id => workspace.to_param, :name_pattern => "view"
      end

      it "filters db objects by type" do
        options = {:entity_subtype => "SANDBOX_TABLE", :limit => 50}
        mock(workspace).datasets(user, options) { the_datasets }
        get :index, :workspace_id => workspace.to_param, :entity_subtype => 'SANDBOX_TABLE'
      end

      it "asks for datasets only from the selected database" do
        options = {:database_id => workspace.sandbox.database.to_param, :limit => 50}
        mock(workspace).datasets(user, options) { the_datasets }
        get :index, :workspace_id => workspace.to_param, :database_id => workspace.sandbox.database.to_param
      end

      describe "limiting datasets to load" do
        it "passes the limit parameter to workspace.datasets in the options hash and adds the sort option" do
          mock(workspace).datasets(anything, {:limit => 5}) { the_datasets }
          get :index, :workspace_id => workspace.to_param, :page => 1, :per_page => 5
        end
        it "sets the limit option to page * per_page" do
          mock(workspace).datasets(anything, {:limit => 20}) { the_datasets }
          get :index, :workspace_id => workspace.to_param, :page => 4, :per_page => 5
        end
      end
    end

    describe "#create" do
      let(:other_view) { datasets(:other_view) }

      it "uses authorization" do
        mock(subject).authorize! :can_edit_sub_objects, workspace
        post :create, :workspace_id => workspace.to_param, :dataset_ids => [other_table.to_param]
      end

      it "should associate one table to the workspace" do
        post :create, :workspace_id => workspace.to_param, :dataset_ids => [other_table.to_param]
        response.code.should == "201"
        response.decoded_body.should_not be_nil
        workspace.bound_datasets.should include(other_table)
      end

      it "should associate multiple tables/views to the workspace for one table" do
        post :create, :workspace_id => workspace.to_param, :dataset_ids => [other_table.to_param, other_view.to_param]
        response.code.should == "201"

        workspace.bound_datasets.should include(other_table)
        workspace.bound_datasets.should include(other_view)
      end

      it "should create event and activity" do
        post :create, :workspace_id => workspace.to_param, :dataset_ids => [other_table.to_param, other_view.to_param]

        events = Events::SourceTableCreated.by(user)
        events.count.should == 2
      end

      context "when associating multiple datasets with a workspace" do
        it "does not show an error if some datasets are already associated" do
          post :create, :workspace_id => workspace.to_param, :dataset_ids => [gpdb_table.to_param, other_table.to_param]
          response.code.should == "201"
        end
      end
    end

    describe "#show" do
      before do
        any_instance_of(GpdbSchema) do |schema|
          stub(schema).verify_in_source(anything) { true }
        end
      end

      it "does not present datasets not associated with the workspace" do
        get :show, :id => other_table.to_param, :workspace_id => workspace.to_param
        response.should be_not_found
      end

      it "uses authorization" do
        mock(subject).authorize! :show, workspace
        get :show, :id => gpdb_table.to_param, :workspace_id => workspace.to_param
      end

      context "when the specified dataset is associated with the workspace" do
        context "when the dataset is a table" do
          let(:dataset) { gpdb_table }

          it "presents the specified dataset, including the workspace" do
            mock_present do |model, _, options|
              model.should == gpdb_table
              options[:workspace].should == workspace
            end

            get :show, :id => dataset.to_param, :workspace_id => workspace.to_param
          end

          generate_fixture "workspaceDataset/datasetTable.json" do
            get :show, :id => dataset.to_param, :workspace_id => workspace.to_param
          end
        end

        context "when the dataset is a view" do
          let(:dataset) { gpdb_view }

          generate_fixture "workspaceDataset/datasetView.json" do
            get :show, :id => dataset.to_param, :workspace_id => workspace.to_param
          end
        end

        context "when the dataset is a source table" do
          let(:the_datasets) { fake_relation [source_table] }

          generate_fixture "workspaceDataset/sourceTable.json" do
            get :show, :id => source_table.to_param, :workspace_id => workspace.to_param
          end
        end

        context "when the dataset is a source view" do
          let(:the_datasets) { fake_relation [source_view] }

          generate_fixture "workspaceDataset/sourceView.json" do
            get :show, :id => source_view.to_param, :workspace_id => workspace.to_param
          end
        end
      end

      context 'when the dataset does not exist in greenplum' do
        before do
          any_instance_of(GpdbTable) do |table|
            stub(table).verify_in_source(anything) { false }
          end
        end

        it 'responds an error http code' do
          get :show, id: gpdb_table.to_param, workspace_id: workspace.to_param
          response.code.should == '422'
        end

        it 'renders the table' do
          get :show, id: gpdb_table.to_param, workspace_id: workspace.to_param
          response.decoded_body.should have_key :response
        end

        it 'renders the database_not_found error' do
          get :show, id: gpdb_table.to_param, workspace_id: workspace.to_param
          response.decoded_body.should have_key :errors
        end
      end

      context 'when the dataset connection blew up' do
        before do
          error = GreenplumConnection::DatabaseError.new(nil)
          mock(error).error_type { :INSTANCE_UNREACHABLE }
          any_instance_of(GpdbTable) do |table|
            stub(table).verify_in_source(anything) { raise error }
          end
        end

        it 'responds an error http code' do
          get :show, id: gpdb_table.to_param, workspace_id: workspace.to_param
          response.code.should == '422'
        end

        it 'renders the table' do
          get :show, id: gpdb_table.to_param, workspace_id: workspace.to_param
          response.decoded_body.should have_key :response
        end

        it 'renders the schema_not_found error' do
          get :show, id: gpdb_table.to_param, workspace_id: workspace.to_param
          response.decoded_body.should have_key :errors
          response.decoded_body[:errors]['record'].should == 'INSTANCE_UNREACHABLE'
        end
      end
    end

    describe "#destroy" do
      it "deletes the association" do
        delete :destroy, :id => source_table.to_param, :workspace_id => workspace.to_param

        response.should be_success
        AssociatedDataset.find_by_dataset_id_and_workspace_id(gpdb_table.to_param, workspace.to_param).should be_nil
      end

      it "uses authorization" do
        mock(subject).authorize! :can_edit_sub_objects, workspace
        delete :destroy, :id => source_table.to_param, :workspace_id => workspace.to_param
      end
    end
  end

  context "with real greenplum", :greenplum_integration do
    let(:user) { users(:admin) }
    let(:workspace) { workspaces(:gpdb_workspace) }
    let(:account) { workspace.sandbox.parent.data_source.account_for_user!(user) }

    before do
      log_in user
    end

    describe "index" do
      context "for a source_table" do
        let(:dataset) { workspace.bound_datasets.first }

        it "works" do
          get :show, :id => dataset.to_param, :workspace_id => workspace.to_param
        end
      end

      context "for a chorus_view" do
        let(:dataset) { datasets(:executable_chorus_view) }
        let(:workspace) { workspaces(:public) }

        it "works" do
          get :show, :id => dataset.to_param, :workspace_id => workspace.to_param
        end
      end

      context "for a sandbox_table" do
        let(:dataset) { workspace.sandbox.datasets.first }

        it "works" do
          get :show, :id => dataset.to_param, :workspace_id => workspace.to_param
        end
      end
    end

    context "when searching within the workspace" do
      context "all the tables have been refreshed into rails" do
        before do
          get :index, :workspace_id => workspace.to_param, :page => "1", :per_page => "5", :name_pattern => "CANDY"
        end

        it "presents the correct count / pagination information" do
          decoded_pagination.records.should == 7
          decoded_pagination.total.should == 2
        end

        it "returns sandbox datasets that aren't on the first page of unfiltered results" do
          decoded_response.map(&:object_name).should include('candy_empty')
        end
      end

      context "There is a newly created GPDB table that hasn't been refreshed into rails yet" do
        it "includes the new table" do
          workspace.sandbox.datasets.where(:name => "candy").first.destroy

          get :index, :workspace_id => workspace.to_param, :page => "1", :per_page => "5", :name_pattern => "CANDY"

          decoded_response.map(&:object_name).should include('2candy')
        end

        context "the new table is on the second page of pagination" do
          it "includes the new table" do
            workspace.sandbox.datasets.where(:name => "candy_empty").first.destroy

            get :index, :workspace_id => workspace.to_param, :page => "1", :per_page => "5", :name_pattern => "CANDY"

            decoded_response.map(&:object_name).should include('candy_empty')
          end
        end
      end

    end

    context "when filtering on a dataset type" do
      before do
        get :index, :workspace_id => workspace.to_param, :page => "1", :per_page => "5", :entity_subtype => entity_subtype
      end

      context "sandbox datasets" do
        let(:entity_subtype) { "SANDBOX_DATASET" }

        it "presents the correct count / pagination information" do
          decoded_pagination.records.should == workspace.datasets(user, :entity_subtype => entity_subtype).count
          decoded_pagination.total.should == (workspace.datasets(user, :entity_subtype => entity_subtype).count/5.0).ceil
        end
      end

      context "chorus views" do
        let(:entity_subtype) { "CHORUS_VIEW" }
        it "presents the correct count / pagination information" do
          decoded_pagination.records.should == workspace.chorus_views.size
          decoded_pagination.total.should == (workspace.chorus_views.size/5.0).ceil
        end
      end

      context "source datasets" do
        let(:entity_subtype) { "SOURCE_TABLE" }
        it "presents the correct count / pagination information" do
          decoded_pagination.records.should == 1
          decoded_pagination.total.should == 1
        end
      end
    end
  end
end
