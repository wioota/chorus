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

  describe 'update from params' do
    context "when uploading an AFM" do
      let(:description) { "Nice workfile, good workfile, I've always wanted a workfile like you" }
      let(:file) { test_file('workflow.afm', "text/xml") }
      let(:workfile) { Workfile.build_for(params) }
      let(:hdfs) { hdfs_data_sources(:hadoop) }
      let(:params) do
        {
            :description => description,
            :entity_subtype => 'alpine',
            :versions_attributes => {"0" => {:contents => file}},
            :hdfs_data_source_id => hdfs.id,
            :database_id => "",
            :workspace => workspace,
            :owner => user
        }
      end

      before do
        any_instance_of(Alpine::API) { |api|
          stub(api).session_id
          stub(api).create_work_flow
        }
      end

      it "resolves name conflicts" do
        workfile.update_from_params!(params)
        workfile.file_name.should eq("workflow")

        second_workfile = Workfile.build_for(params)
        second_workfile.update_from_params!(params)
        second_workfile.file_name.should eq("workflow_1")
      end

      describe "notifying alpine" do
        let(:file_contents) do
          contents = params[:versions_attributes]['0'][:contents].read
          params[:versions_attributes]['0'][:contents].rewind
          contents
        end

        it "POSTs the correct xml" do
          mock(Alpine::API).create_work_flow(model, file_contents)
          model.update_from_params!(params)
        end

        context "when alpine responds with a failure" do
          before do
            any_instance_of(Alpine::API) { |api| stub(api).create_work_flow(model, file_contents) { raise Net::ProtocolError.new } }
          end

          it "should not create the workfile" do
            expect {
              model.update_from_params!(params)
            }.to raise_error(ApiValidationError)
            Workfile.find_by_id(workfile.id).should be_nil
          end
        end
      end
    end
  end

  describe "validations" do
    it { should validate_presence_of :execution_location }

    context "with an archived workspace" do
      let(:workspace) { workspaces(:archived) }

      context "on create" do
        it "is invalid" do
          model.errors_on(:workspace).should include(:ARCHIVED)
        end
      end

      context "on update" do
        let(:model) { workfiles('alpine_flow') }

        it "is valid" do
          model.workspace = workspace
          model.workspace.should be_archived
          model.update_attributes(:file_name => 'foobar')
          model.errors_on(:workspace).should_not be_present
        end
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
      context "in a DB" do
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

      context "in a Hadoop Filesystem" do
        let(:datasetA) { datasets(:hadoop) }
        let(:datasetB) { FactoryGirl.create(:hdfs_dataset, :hdfs_data_source => datasetA.hdfs_data_source) }
        let(:params) { {dataset_ids: [datasetA.id, datasetB.id], workspace: workspace} }

        it 'sets the execution location to the HdfsDatSource where the datasets live' do
          AlpineWorkfile.create(params).execution_location.should == datasetA.hdfs_data_source
        end

        context "and the datasets are from multiple Hdfs Data Sources" do
          let(:datasetB) { FactoryGirl.create(:hdfs_dataset) }

          it "assigns too_many_datasources error" do
            AlpineWorkfile.create(params).errors_on(:datasets).should include(:too_many_databases)
          end
        end
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