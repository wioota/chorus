require 'spec_helper'

describe ActivityMigrator, :legacy_migration => true, :type => :legacy_migration do
  describe ".migrate" do
    before do
      UserMigrator.new.migrate
      WorkspaceMigrator.new.migrate
      InstanceMigrator.new.migrate
      HadoopInstanceMigrator.new.migrate
      WorkfileMigrator.new.migrate
    end

    context "migrating activities that reference datasets" do
      before do
        InstanceAccountMigrator.new.migrate
        ActivityMigrator.new.migrate
      end

      it "creates new events for all legacy activities" do
        Events::Base.count.should > 0
      end

      it "copies SOURCE TABLE CREATED data fields from the legacy activity" do
        event = Events::SOURCE_TABLE_CREATED.find(event_id_for('10002'))

        event.workspace.should be_instance_of(Workspace)
        event.actor.should be_instance_of(User)
        event.dataset.should be_a(Dataset)
        event.created_at.to_s.should == "2012-03-07 17:59:20 UTC"
      end

      it "copies WORKSPACE_ADD_HDFS_AS_EXT_TABLE fields from the legacy activity" do
        event = Events::WORKSPACE_ADD_HDFS_AS_EXT_TABLE.find(event_id_for('10718'))
        event.workspace.should be_instance_of(Workspace)
        event.actor.should be_instance_of(User)
        event.dataset.should be_a(Dataset)
        event.hdfs_file.should be_a(HdfsFileReference)
        event.hdfs_file.hadoop_instance_id.should_not be_nil
        event.hdfs_file.path.should == "/data/Top_1_000_Songs_To_Hear_Before_You_Die.csv"
      end

      it "copies IMPORT SUCCESS activities" do
        event = Events::IMPORT_SUCCESS.find(event_id_for('10177'))
        event.workspace.should be_a(Workspace)
        event.workspace.name.should == "ws"
        event.actor.should be_a(User)
        event.actor.username.should == "edcadmin"
        event.dataset.should be_a(Dataset)
        event.dataset.name.should == "sixrows33columns"
        event.additional_data[:filename].should == "sixrows33columns.csv"
        event.additional_data[:import_type].should == "file"
      end

      it "copies IMPORT FAILURE activities" do
        event = Events::IMPORT_FAILED.find(event_id_for('10368'))
        event.workspace.should be_a(Workspace)
        event.workspace.name.should == "active_public"
        event.actor.should be_a(User)
        event.actor.username.should == "edcadmin"
        event.additional_data[:filename].should == "SFO 2011 Annual Survey.csv"
        event.additional_data[:import_type].should == "file"
        event.additional_data[:destination_table].should == "sfo_2011_annual_survey"
        event.additional_data[:error_message].should == "[ERROR: invalid input syntax for type double precision: \"1,909.00\"\n  Where: COPY sfo_2011_annual_survey, line 3851, column runid]"
      end
    end

    context "migrating activities that do not reference datasets" do
      before do
        ActivityMigrator.new.migrate
      end

      it "copies PUBLIC WORKSPACE CREATED data fields from the legacy activity" do
        event = Events::PUBLIC_WORKSPACE_CREATED.find(event_id_for('10158'))

        event.workspace.should be_instance_of(Workspace)
        event.actor.should be_instance_of(User)
      end

      it "copied WORKSPACE_ARCHIVED data fields from the legacy activity" do
        event = Events::WORKSPACE_ARCHIVED.find(event_id_for('10304'))

        event.workspace.should be_instance_of(Workspace)
        event.actor.should be_instance_of(User)
      end

      it "copied WORKSPACE_ARCHIVED data fields from the legacy activity" do
        event = Events::WORKSPACE_ARCHIVED.find(event_id_for('10304'))

        event.workspace.should be_instance_of(Workspace)
        event.actor.should be_instance_of(User)
      end

      it "copied WORKSPACE_UNARCHIVED data fields from the legacy activity" do
        Events::WORKSPACE_UNARCHIVED.count.should == 1
        event = Events::WORKSPACE_UNARCHIVED.find(event_id_for('10721'))

        event.workspace.should be_instance_of(Workspace)
        event.actor.should be_instance_of(User)
      end

      it "copies PRIVATE WORKSPACE CREATED data fields from the legacy activity" do
        event = Events::PRIVATE_WORKSPACE_CREATED.find(event_id_for('10401'))

        event.workspace.should be_instance_of(Workspace)
        event.actor.should be_instance_of(User)
      end

      it "copies WORKSPACE MAKE PUBLIC data fields from the legacy activity" do
        event = Events::WORKSPACE_MAKE_PUBLIC.find(event_id_for('10719'))

        event.workspace.should be_instance_of(Workspace)
        event.actor.should be_instance_of(User)
      end

      it "copies WORKSPACE MAKE PRIVATE data fields from the legacy activity" do
        event = Events::WORKSPACE_MAKE_PRIVATE.find(event_id_for('10720'))

        event.workspace.should be_instance_of(Workspace)
        event.actor.should be_instance_of(User)
      end

      it "copies WORKFILE CREATED data fields from the legacy activity" do
        event = Events::WORKFILE_CREATED.find(event_id_for('10010'))

        event.workspace.should be_instance_of(Workspace)
        event.actor.should be_instance_of(User)
        event.workfile.should be_instance_of(Workfile)
      end

      it "copies INSTANCE CREATED (greenplum) data fields from the legacy activity" do
        event = Events::GREENPLUM_INSTANCE_CREATED.find(event_id_for('10036'))

        event.workspace.should be_blank
        event.actor.should be_instance_of(User)
        event.greenplum_instance.should be_instance_of(Instance)
      end

      it "copies INSTANCE CREATED (hadoop) data fields from the legacy activity" do
        event = Events::HADOOP_INSTANCE_CREATED.find(event_id_for('10006'))

        event.workspace.should be_blank
        event.actor.should be_instance_of(User)
        event.hadoop_instance.should be_instance_of(HadoopInstance)
      end

      it "copies USER ADDED data fields from the legacy activity" do
        event = Events::USER_ADDED.find(event_id_for('10195'))

        event.actor.should be_instance_of(User)
        event.new_user.should be_instance_of(User)
      end
    end

    context "foreign key" do
      before(:each) do
        Legacy.connection.column_exists?(:edc_activity_stream, :chorus_rails_event_id).should be_false
        ActivityMigrator.new.migrate
      end

      it "adds the new foreign key column to legacy table" do
        Legacy.connection.column_exists?(:edc_activity_stream, :chorus_rails_event_id).should be_true
      end

      it "sets the Event id when successfully imported" do
        count = Legacy.connection.exec_query("SELECT COUNT(1) FROM edc_activity_stream WHERE chorus_rails_event_id IS NOT NULL")
        count[0]['count'].to_i.should > 0
      end
    end
  end

  def event_id_for(id)
    activity_stream = Legacy.connection.exec_query("SELECT chorus_rails_event_id FROM edc_activity_stream WHERE id = '#{id}'")
    activity_stream[0]['chorus_rails_event_id']
  end
end
