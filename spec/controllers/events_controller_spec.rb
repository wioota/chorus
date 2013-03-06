require "spec_helper"

describe EventsController do
  let(:current_user) { users(:the_collaborator) }

  before do
    log_in current_user
  end

  describe "#index" do
   it "returns the events with the newest one first" do
     mock_present { |models| models.first.id.should > models.second.id }
     get :index, :entity_type => "dashboard"
     response.code.should == "200"
   end

    context "getting activities for a particular model" do
      let(:event) { Events::Base.last }
      before do
        Activity.create!(:entity => object, :event => event)
      end

      context "for a gpdb instance" do
        let(:object) { data_sources(:default) }

        it "presents the gpdb instance's activities" do
          mock_present { |models| models.should include(event) }
          get :index, :entity_type => "gpdb_data_source", :entity_id => object.id
          response.code.should == "200"
        end
      end

      context "for a hadoop instance" do
        let(:object) { hadoop_instances(:hadoop) }

        it "presents the hadoop instance's activities" do
          mock_present { |models| models.should include(event) }
          get :index, :entity_type => "hadoop_instance", :entity_id => object.id
          response.code.should == "200"
        end
      end

      context "for a user" do
        let(:object) { users(:owner) }

        it "presents the user's activities" do
          any_instance_of(User) { |u| mock.proxy(u).accessible_events(current_user) }
          mock_present { |models| models.should include(event) }
          get :index, :entity_type => "user", :entity_id => object.id
          response.code.should == "200"
        end
      end

      context "for a workfile" do
        let(:object) { workfiles(:private) }

        it "presents the workfile's activities" do
          log_in(users(:owner))
          mock_present { |models| models.should include(event) }
          get :index, :entity_type => "workfile", :entity_id => object.id
          response.code.should == "200"
        end

        context "when you are not authorized to see a workfile" do
          it "returns forbidden" do
            log_in(users(:default))
            get :index, :entity_type => "workfile", :entity_id => object.id

            response.should be_forbidden
          end
        end
      end

      context "for a linked tableau workfile" do
        let(:object) { workfiles(:private_tableau) }

        it "presents the tableau workfile's activities" do
          log_in(users(:owner))
          mock_present { |models| models.should include(event) }
          get :index, :entity_type => "workfile", :entity_id => object.id
          response.code.should == "200"
        end

        context "when you are not authorized to see a tableau workfile" do
          it "returns forbidden" do
            log_in(users(:default))
            get :index, :entity_type => "workfile", :entity_id => object.id

            response.should be_forbidden
          end
        end
      end

      context "for a chorus view" do
        let(:object) { datasets(:private_chorus_view) }

        it "presents the chorus_view's activities" do
          log_in(users(:owner))
          mock_present { |models| models.should include(event) }
          get :index, :entity_type => "dataset", :entity_id => object.id
          response.code.should == "200"
        end

        context "when you are not authorized to see a chorus_view" do
          it "returns forbidden" do
            log_in(users(:default))
            get :index, :entity_type => "dataset", :entity_id => object.id

            response.should be_forbidden
          end
        end
      end

      context "for a GPDB view" do
        let(:object) { datasets(:view) }

        it "presents the GPDB view's activities" do
          log_in(users(:owner))
          mock_present { |models| models.should include(event) }
          get :index, :entity_type => "dataset", :entity_id => object.id
          response.code.should == "200"
        end
      end

      context "for a workspace" do
        let(:object) { workspaces(:private) }

        it "presents the workspace's activities" do
          log_in(users(:owner))
          mock_present { |models| models.should include(event) }
          get :index, :entity_type => "workspace", :entity_id => object.id
          response.code.should == "200"
        end

        context "when you are not authorized to see a workspace" do
          it "returns forbidden" do
            log_in(users(:default))
            get :index, :entity_type => "workspace", :entity_id => object.id

            response.should be_forbidden
          end
        end
      end

      context "for a gpdb_table" do
        let(:object) { datasets(:table) }

        it "presents the gpdb_table's activities" do
          log_in(users(:owner))
          mock_present { |models| models.should include(event) }
          get :index, :entity_type => "dataset", :entity_id => object.id

          response.code.should == "200"
        end
      end

      context "for an hdfs file" do
        let(:object) { HdfsEntry.last }

        it "presents the workspace's activities" do
          mock_present { |models| models.should include(event) }
          get :index, :entity_type => "hdfs_file", :entity_id => object.id
          response.code.should == "200"
        end
      end

      context "for the current user's home page" do
        let(:object) { datasets(:table) }

        before do
          mock(Events::Base).for_dashboard_of(current_user) { fake_relation [event] }
        end

        it "presents the user's activities" do
          mock_present do |models, view, options|
            models.should == [event]
            options[:activity_stream].should be_true
          end
          get :index, :entity_type => "dashboard"
          response.code.should == "200"
        end
      end
    end
  end

  describe "#show" do
    let(:event) { events(:note_on_no_collaborators_private) }

    it "shows the particular event " do
      mock_present do |model, view, options|
        model.should == event
        options[:activity_stream].should be_true
      end
      log_in users(:no_collaborators)
      get :show, :id => event.to_param
      response.code.should == "200"
    end

    it "returns an error when trying to show an activity for which the user doesn't have access" do
      log_in users(:owner)
      get :show, :id => event.to_param
      response.code.should == "404"
    end

    context "when the workspace is public" do
      let(:event) { events(:note_on_no_collaborators_public) }

      it "should show the event" do
        log_in users(:owner)
        get :show, :id => event.to_param
        response.code.should == "200"
      end
    end

    context "when the user is an admin and the workspace is private" do
      it "should show the event" do
        log_in users(:admin)
        get :show, :id => event.to_param
        response.code.should == "200"
      end
    end

    FIXTURE_FILES = {
        'dataSourceCreated' => Events::DataSourceCreated,
        'gnipInstanceCreated' => Events::GnipInstanceCreated,
        'hadoopInstanceCreated' => Events::HadoopInstanceCreated,
        'greenplumInstanceChangedOwner' => Events::GreenplumInstanceChangedOwner,
        'greenplumInstanceChangedName' => Events::GreenplumInstanceChangedName,
        'hadoopInstanceChangedName' => Events::HadoopInstanceChangedName,
        'publicWorkspaceCreated' => Events::PublicWorkspaceCreated,
        'privateWorkspaceCreated' => Events::PrivateWorkspaceCreated,
        'workspaceMakePublic' => Events::WorkspaceMakePublic,
        'workspaceMakePrivate' => Events::WorkspaceMakePrivate,
        'workspaceArchived' => Events::WorkspaceArchived,
        'workspaceUnarchived' => Events::WorkspaceUnarchived,
        'workfileCreated' => Events::WorkfileCreated,
        'sourceTableCreated' => Events::SourceTableCreated,
        'userCreated' => Events::UserAdded,
        'sandboxAdded' => Events::WorkspaceAddSandbox,
        'noteOnGreenplumInstanceCreated' => Events::NoteOnGreenplumInstance.where(:insight => false),
        'insightOnGreenplumInstance' => Events::NoteOnGreenplumInstance.where(:insight => true),
        'noteOnGnipInstanceCreated' => Events::NoteOnGnipInstance.where(:insight => false),
        'insightOnGnipInstanceCreated' => Events::NoteOnGnipInstance.where(:insight => true),
        'noteOnHadoopInstanceCreated' => Events::NoteOnHadoopInstance,
        'noteOnHdfsFileCreated' => Events::NoteOnHdfsFile,
        'noteOnWorkspaceCreated' => Events::NoteOnWorkspace,
        'noteOnWorkfileCreated' => Events::NoteOnWorkfile,
        'noteOnDatasetCreated' => Events::NoteOnDataset,
        'noteOnWorkspaceDatasetCreated' => Events::NoteOnWorkspaceDataset,
        'membersAdded' => Events::MembersAdded,
        'fileImportCreated' => Events::FileImportCreated,
        'fileImportSuccess' => Events::FileImportSuccess,
        'fileImportFailed' => Events::FileImportFailed,
        'workspaceImportCreated' => Events::WorkspaceImportCreated,
        'workspaceImportSuccess' => Events::WorkspaceImportSuccess,
        'workspaceImportFailed' => Events::WorkspaceImportFailed,
        'workfileUpgradedVersion' => Events::WorkfileUpgradedVersion,
        'workfileVersionDeleted' => Events::WorkfileVersionDeleted,
        'chorusViewCreatedFromWorkfile' => Events::ChorusViewCreated.from_workfile,
        'chorusViewCreatedFromDataset' => Events::ChorusViewCreated.from_dataset,
        'chorusViewChanged' => Events::ChorusViewChanged,
        'workspaceChangeName' => Events::WorkspaceChangeName,
        'tableauWorkbookPublished' => Events::TableauWorkbookPublished,
        'tableauWorkfileCreated' => Events::TableauWorkfileCreated,
        'gnipStreamImportCreated' => Events::GnipStreamImportCreated,
        'gnipStreamImportSuccess' => Events::GnipStreamImportSuccess,
        'gnipStreamImportFailed' => Events::GnipStreamImportFailed,
        'viewCreated' => Events::ViewCreated,
        'importScheduleUpdated' => Events::ImportScheduleUpdated,
        'importScheduleDeleted' => Events::ImportScheduleDeleted,
        'workspaceDeleted' => Events::WorkspaceDeleted,
        'hdfsFileExtTableCreated' => Events::HdfsFileExtTableCreated,
        'hdfsDirectoryExtTableCreated' => Events::HdfsDirectoryExtTableCreated,
        'hdfsPatternExtTableCreated' => Events::HdfsPatternExtTableCreated,
        'schemaImportSuccess' => Events::SchemaImportSuccess,
        'schemaImportFailed' => Events::SchemaImportFailed
    }

    FIXTURE_FILES.each do |file_name, event_relation|
      generate_fixture "activity/#{file_name}.json" do
        event = event_relation.last!
        Activity.global.create!(:event => event)
        get :show, :id => event.to_param
      end
    end

    generate_fixture "activity/datasetImportFailedWithModelErrors.json" do
      event = events(:import_failed_with_model_errors)
      Activity.global.create!(:event => event)
      get :show, :id => event.to_param
    end
  end
end
