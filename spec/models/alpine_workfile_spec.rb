require "spec_helper"

describe AlpineWorkfile do
  let(:workspace) { workspaces(:public) }
  let(:user) { workspace.owner }
  let(:params) do
    {:workspace => workspace, :entity_subtype => "alpine",
     :file_name => "sfgj", :dataset_ids => [datasets(:table).id], :owner => user}
  end
  let(:model) { Workfile.build_for(params).tap { |file| file.save } }

  it { should belong_to :execution_location }

  describe "validations" do
    it { should validate_presence_of :execution_location }

    context "with an archived workspace" do
      let(:workspace) { workspaces(:archived) }

      it "is invalid" do
        model.errors_on(:workspace).should include(:ARCHIVED)
      end
    end

    context 'file name with valid characters' do
      it 'is valid' do
        params[:file_name] = 'work_(-file).sql'
        model.should be_valid
      end
    end

    context 'file name with question mark' do
      it 'is not valid' do
        params[:file_name] = 'workfile?.sql'
        model.should have_error_on(:file_name)
      end
    end

    context 'file name with a slash' do
      it 'is not valid' do
        params[:file_name] = 'a/file.sql'
        model.should have_error_on(:file_name)
      end
    end
  end

  it "has a content_type of work_flow" do
    model.content_type.should == 'work_flow'
  end

  it "has an entity_subtype of 'alpine'" do
    model.entity_subtype.should == 'alpine'
  end

  describe 'destruction' do
    it 'notifies Alpine' do
      mock(Alpine::API).delete_work_flow(model)
      model.destroy
    end
  end

  describe "new" do
    context "when passed datasets" do
      let(:datasetA) { datasets(:table) }
      let(:datasetB) { datasets(:other_table) }
      let(:params) { {dataset_ids: [datasetA.id, datasetB.id], workspace: workspace} }

      it 'sets the execution location to the GpdbDatabase where the datasets live' do
        AlpineWorkfile.create(params).execution_location.should == datasetA.database
      end

      it 'assigns the datasets' do
        AlpineWorkfile.create(params).datasets.should =~ [datasetA, datasetB]
      end

      context "and the datasets are from multiple databases" do
        let(:datasetB) { FactoryGirl.create(:gpdb_table) }

        it "assigns too_many_databases error" do
          AlpineWorkfile.create(params).errors_on(:datasets).should include(:too_many_databases)
        end
      end

      context "and at least one of the datasets is a chorus view" do
        let(:datasetB) { datasets(:chorus_view) }

        it "assigns too_many_databases error" do
          AlpineWorkfile.create(params).errors_on(:datasets).should include(:chorus_view_selected)
        end
      end
    end

    context "when passed hdfs entries" do
      let(:hdfs_entry_A) { hdfs_entries(:hdfs_entries_001) }
      let(:hdfs_entry_B) { hdfs_entries(:hdfs_entries_002) }
      let(:params) { {hdfs_entry_ids: [hdfs_entry_A.id, hdfs_entry_B.id], workspace: workspace} }

      it 'sets the execution location to the Hdfs Data Source where the hdfs entries live' do
        AlpineWorkfile.create(params).execution_location.should == hdfs_entry_A.hdfs_data_source
      end

      it 'assigns the hdfs entries' do
        AlpineWorkfile.create(params).hdfs_entries.should =~ [hdfs_entry_A, hdfs_entry_B]
      end

      it 'does not have errors related to the hdfs entries' do
        AlpineWorkfile.create(params).should_not have_error_on(:hdfs_entries)
      end

      context "and the hdfs entries are from multiple Hdfs Data Sources" do
        let(:hdfs_entry_B) { FactoryGirl.create(:hdfs_entry) }

        it "assigns too_many_databases error" do
          AlpineWorkfile.create(params).errors_on(:hdfs_entries).should include(:too_many_hdfs_data_sources)
        end
      end
    end

    context "when passed hdfs entries and gpdb datasets" do
      let(:datasetA) { datasets(:table) }
      let(:datasetB) { datasets(:other_table) }
      let(:hdfs_entry_A) { hdfs_entries(:hdfs_entries_001) }
      let(:hdfs_entry_B) { hdfs_entries(:hdfs_entries_002) }
      let(:dataset_ids) { [datasetA.id, datasetB.id] }
      let(:hdfs_entry_ids) { [hdfs_entry_A.id, hdfs_entry_B.id] }
      let(:params) do
        {
          :dataset_ids => dataset_ids,
          :hdfs_entry_ids => hdfs_entry_ids,
          :workspace => workspace
        }
      end

      it "is invalid" do
        AlpineWorkfile.create(params).should have_error_on(:base)
          .with_message(:incompatible_params)
          .with_options(:fields => "dataset_ids, hdfs_entry_ids")
      end
    end
  end

  describe "#attempt_data_source_connection" do
    before do
      set_current_user(user)
    end

    it "tries to connect using the data source" do
      mock(model.data_source).attempt_connection(user)
      model.attempt_data_source_connection
    end
  end

  describe "#data_source" do
    let(:database) { gpdb_databases(:default) }
    let(:workfile) { AlpineWorkfile.create(workspace: workspace) }

    it "returns the database's data source" do
      workfile.execution_location = database
      workfile.data_source.should == database.data_source
    end
  end

  describe "#latest_workfile_version" do
    it 'returns nil' do
      model.latest_workfile_version.should be_nil
    end
  end

  describe "#create_new_version" do
    let(:event_params) do
      {
        :commit_message => 'new work flow'
      }
    end

    it 'creates a workfile version upgrade event with the provided commit message' do
      expect do
        model.create_new_version(user, event_params)
      end.to change(Events::WorkFlowUpgradedVersion, :count).by(1)

      event = Events::WorkFlowUpgradedVersion.last
      event.commit_message.should == 'new work flow'
      event.workfile.should == model
      event.workspace.should == model.workspace
    end
  end
end