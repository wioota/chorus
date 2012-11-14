require 'legacy_migration_spec_helper'

describe ActivityMigrator do
  describe ".migrate" do
    context "migrating activities that reference datasets" do
      it "copies SOURCE TABLE CREATED data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT * from legacy_migrate.edc_activity_stream ed where type = 'SOURCE_TABLE_CREATED'")
        rows.each do |row|
          event = Events::SourceTableCreated.find_by_legacy_id!(row["id"])
          event.workspace.should be_instance_of(Workspace)
          event.actor.should be_instance_of(User)
          event.dataset.should be_a(Dataset)
          event.created_at.should == row["created_tx_stamp"]
        end
        rows.count.should > 0 
        Events::SourceTableCreated.count.should == rows.count
      end

      it "copies CHORUS VIEW CREATED data fields from the legacy activity, for chorus views created from workfiles" do
        rows = Legacy.connection.select_all("
          SELECT eas.*, easo.object_id AS workfile_id FROM legacy_migrate.edc_activity_stream eas
          LEFT JOIN legacy_migrate.edc_activity_stream_object easo
            ON eas.id = easo.activity_stream_id
          WHERE type = 'CHORUS_VIEW_CREATED'
          AND object_id NOT LIKE '%|%'
          AND easo.entity_type = 'sourceObject';
          ")
        rows.each do |row|
          event = Events::ChorusViewCreated.find_by_legacy_id!(row["id"])
          event.workspace.should be_instance_of(Workspace)
          event.actor.should be_instance_of(User)
          event.dataset.should be_a(Dataset)
          event.source_object.should == Workfile.find_by_legacy_id(row['workfile_id'])
          event.created_at.should == row["created_tx_stamp"]
        end
        rows.count.should > 0 
        Events::ChorusViewCreated.where(:target2_type => 'Workfile').count.should == rows.count
      end

      it "copies CHORUS VIEW CREATED data fields from the legacy activity, for chorus views created from datasets" do
        rows = Legacy.connection.select_all("
          SELECT eas.* FROM legacy_migrate.edc_activity_stream eas
          LEFT JOIN legacy_migrate.edc_activity_stream_object easo
            ON eas.id = easo.activity_stream_id
          WHERE type = 'CHORUS_VIEW_CREATED'
          AND object_id LIKE '%|%'
          AND easo.entity_type = 'sourceObject';
          ")

        rows.each do |row|
          event = Events::ChorusViewCreated.find_by_legacy_id!(row["id"])
          event.workspace.should be_instance_of(Workspace)
          event.actor.should be_instance_of(User)
          event.dataset.should be_a(Dataset)
          event.source_object.should be_a(Dataset)
          event.created_at.should == row["created_tx_stamp"]
        end
        rows.count.should > 0 
        Events::ChorusViewCreated.where(:target2_type => 'Dataset').count.should == rows.count
      end

      it "copies VIEW CREATED data fields from the legacy activity" do
        rows = Legacy.connection.select_all("
          SELECT eas.* FROM legacy_migrate.edc_activity_stream eas
          LEFT JOIN legacy_migrate.edc_activity_stream_object easo
            ON eas.id = easo.activity_stream_id
          WHERE type = 'VIEW_CREATED'
          AND easo.entity_type = 'view';
          ")

        rows.each do |row|
          event = Events::ViewCreated.find_by_legacy_id!(row["id"])
          event.workspace.should be_instance_of(Workspace)
          event.actor.should be_instance_of(User)
          event.dataset.should be_a(Dataset)
          event.source_dataset.should be_a(ChorusView)
          event.created_at.should == row["created_tx_stamp"]
        end
        rows.count.should > 0 
        Events::ViewCreated.count.should == rows.count
      end


      it "copies DATASET CHANGED QUERY events for when users edit chorus views" do
        rows = Legacy.connection.select_all("
          SELECT eas.*, normalize_key(easo.object_id) as legacy_dataset_id FROM legacy_migrate.edc_activity_stream eas
          LEFT JOIN legacy_migrate.edc_activity_stream_object easo
            ON eas.id = easo.activity_stream_id
            AND easo.object_type = 'object'
          WHERE type = 'DATASET_CHANGED_QUERY';
          ")

        rows.each do |row|
          event = Events::ChorusViewChanged.find_by_legacy_id!(row["id"])
          event.workspace.should == Workspace.unscoped.find_by_legacy_id(row['workspace_id'])
          event.actor.username == row['author']
          event.dataset.should == Dataset.unscoped.find_by_legacy_id(row['legacy_dataset_id'])
          event.created_at.should == row["created_tx_stamp"]
        end
        Events::ChorusViewChanged.count.should == rows.count
      end

      #it "copies WORKSPACE_ADD_HDFS_AS_EXT_TABLE fields from the legacy activity" do
      #  #expect {
      #  #  ActivityMigrator.migrate
      #  #}.to change(Events::WorkspaceAddHdfsAsExtTable, :count).by(1)
      #
      #  event = Events::WorkspaceAddHdfsAsExtTable.find(event_id_for('10718'))
      #  event.workspace.should be_instance_of(Workspace)
      #  event.actor.should be_instance_of(User)
      #  event.dataset.should be_a(Dataset)
      #  event.hdfs_file.should be_a(HdfsEntry)
      #  event.hdfs_file.hadoop_instance_id.should_not be_nil
      #  event.hdfs_file.path.should == "/data/Top_1_000_Songs_To_Hear_Before_You_Die.csv"
      #end

      it "copies FILE IMPORT CREATED events" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_name as table_name, aso.object_id  from legacy_migrate.edc_activity_stream ed LEFT JOIN
          legacy_migrate.edc_activity_stream_object as aso  ON ed.id = aso.activity_stream_id and aso.entity_type = 'table' where
          type = 'IMPORT_CREATED' and indirect_verb = 'of file';")
        rows.each do |row|
          event = Events::FileImportCreated.find_by_legacy_id(row["id"])
          event.workspace.legacy_id.should == row["workspace_id"]
          event.actor.username.should == row["author"]
          event.dataset.name.should == row["table_name"]
          event.additional_data['file_name'].should == row["entity_name"]
          event.additional_data['import_type'].should == "file"
          event.additional_data['destination_table'].should == row["table_name"]
        end
        rows.count.should > 0 
        Events::FileImportCreated.count.should == rows.count
      end

      it "copies FILE IMPORT SUCCESS events" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_name as table_name, aso.object_id  from legacy_migrate.edc_activity_stream ed LEFT JOIN
          legacy_migrate.edc_activity_stream_object as aso  ON ed.id = aso.activity_stream_id and aso.entity_type = 'table' where
          type = 'IMPORT_SUCCESS' and indirect_verb = 'of file';")
        rows.each do |row|
          event = Events::FileImportSuccess.find_by_legacy_id(row['id'])
          event.workspace.legacy_id.should == row["workspace_id"]
          event.actor.username.should == row["author"]
          event.dataset.name.should == row["table_name"]
          event.additional_data['file_name'].should == row["entity_name"]
          event.additional_data['import_type'].should == "file"
        end
        rows.count.should > 0 
        Events::FileImportSuccess.count.should == rows.count
      end

      it "copies FILE IMPORT FAILED events" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_name as table_name, aso.object_id, et.result as result  from legacy_migrate.edc_activity_stream ed LEFT JOIN
          legacy_migrate.edc_activity_stream_object as aso  ON ed.id = aso.activity_stream_id and aso.entity_type = 'table'
          LEFT JOIN legacy_migrate.edc_activity_stream_object aso2 ON aso2.activity_stream_id = aso.activity_stream_id AND aso2.entity_type = 'task'
          LEFT JOIN legacy_migrate.edc_task et ON et.id = aso2.object_id where
          type = 'IMPORT_FAILED' and indirect_verb = 'of file';")
        rows.each do |row|
          event = Events::FileImportFailed.find_by_legacy_id(row['id'])
          event.workspace.legacy_id.should == row["workspace_id"]
          event.actor.username.should == row["author"]
          event.additional_data['file_name'].should == row["entity_name"]
          event.additional_data['import_type'].should == "file"
          event.additional_data['destination_table'].should == row["table_name"]
          event.additional_data['error_message'].should == row["result"]
        end
        rows.count.should > 0 
        Events::FileImportFailed.count.should == rows.count
      end

      it "copies DATASET IMPORT CREATED events" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_name as table_name, source_dataset_aso.object_name as source_table_name, aso.object_id from legacy_migrate.edc_activity_stream ed
          LEFT JOIN legacy_migrate.edc_activity_stream_object as aso
            ON ed.id = aso.activity_stream_id and aso.entity_type = 'table'
          LEFT JOIN legacy_migrate.edc_activity_stream_object as source_dataset_aso
            ON ed.id = source_dataset_aso.activity_stream_id and source_dataset_aso.entity_type IN ('databaseObject', 'chorusView')
          where type = 'IMPORT_CREATED' and indirect_verb = 'of dataset';")
        rows.each do |row|
          event = Events::DatasetImportCreated.find_by_legacy_id(row['id'])
          event.workspace.legacy_id.should == row["workspace_id"]
          event.actor.username.should == row["author"]
          event.dataset.name.should == row["table_name"]
          event.source_dataset.name.should == row["source_table_name"]
          event.additional_data['destination_table'].should == row["table_name"]
        end
        rows.count.should > 0 
        Events::DatasetImportCreated.count.should == rows.count
      end

      it "copies IMPORT SCHEDULE UPDATED events" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_name as table_name, source_dataset_aso.object_name as source_table_name, aso.object_id from legacy_migrate.edc_activity_stream ed
          LEFT JOIN legacy_migrate.edc_activity_stream_object as aso
            ON ed.id = aso.activity_stream_id and aso.entity_type = 'table'
          LEFT JOIN legacy_migrate.edc_activity_stream_object as source_dataset_aso
            ON ed.id = source_dataset_aso.activity_stream_id and source_dataset_aso.entity_type IN ('databaseObject', 'chorusView')
          where type = 'IMPORT_UPDATED';")
        rows.each do |row|
          event = Events::ImportScheduleUpdated.find_by_legacy_id(row['id'])
          event.workspace.legacy_id.should == row["workspace_id"]
          event.actor.username.should == row["author"]
          event.dataset.name.should == row["table_name"]
          event.source_dataset.name.should == row["source_table_name"]
          event.additional_data['destination_table'].should == row["table_name"]
        end
        rows.count.should > 0 
        Events::ImportScheduleUpdated.count.should == rows.count
      end

      it "copies DATASET IMPORT SUCCESS events" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_name as table_name, source_dataset_aso.object_name as source_table_name, aso.object_id from legacy_migrate.edc_activity_stream ed
          LEFT JOIN legacy_migrate.edc_activity_stream_object as aso
            ON ed.id = aso.activity_stream_id and aso.entity_type = 'table'
          LEFT JOIN legacy_migrate.edc_activity_stream_object as source_dataset_aso
            ON ed.id = source_dataset_aso.activity_stream_id and source_dataset_aso.entity_type IN ('databaseObject','chorusView')
          where type = 'IMPORT_SUCCESS' and indirect_verb = 'of dataset';")
        rows.each do |row|
          event = Events::DatasetImportSuccess.find_by_legacy_id(row['id'])
          event.workspace.legacy_id.should == row["workspace_id"]
          event.actor.username.should == row["author"]
          event.dataset.name.should == row["table_name"]
          event.source_dataset.name.should == row["source_table_name"]
        end
        rows.count.should > 0
        Events::DatasetImportSuccess.count.should == rows.count
      end

      it "copies DATASET IMPORT FAILED events" do
        rows = Legacy.connection.select_all(<<-SQL
        SELECT ed.*, aso.object_name as table_name,
          source_dataset_aso.object_name as source_table_name,
          aso.object_id, et.result as result FROM legacy_migrate.edc_activity_stream ed
          LEFT JOIN legacy_migrate.edc_activity_stream_object as source_dataset_aso
            ON ed.id = source_dataset_aso.activity_stream_id and source_dataset_aso.entity_type IN ('databaseObject', 'chorusView')
          LEFT JOIN legacy_migrate.edc_activity_stream_object as aso
            ON ed.id = aso.activity_stream_id and aso.entity_type = 'table'
          LEFT JOIN legacy_migrate.edc_activity_stream_object aso2
            ON ed.id = aso2.activity_stream_id AND aso2.entity_type = 'task'
          LEFT JOIN legacy_migrate.edc_task et ON et.id = aso2.object_id where
          type = 'IMPORT_FAILED' and indirect_verb = 'of dataset';
        SQL
        )

        rows.each do |row|
          event = Events::DatasetImportFailed.find_by_legacy_id(row['id'])
          event.workspace.legacy_id.should == row["workspace_id"]
          event.actor.username.should == row["author"]
          event.source_dataset.name.should == row['source_table_name']
          event.additional_data['destination_table'].should == row["table_name"]
          p row if event.additional_data['error_message'] != row["result"]
          event.additional_data['error_message'].should == row["result"]
        end
        rows.count.should > 0
        Events::DatasetImportFailed.count.should == rows.count
      end
    end

    context "migrating events that do not reference datasets" do
      it "copies PUBLIC WORKSPACE CREATED data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed INNER JOIN
        legacy_migrate.edc_workspace as ew  ON ew.id = ed.entity_id and ew.is_public = true where
        type = 'WORKSPACE_CREATED' ;")
        rows.each do |row|
          event = Events::PublicWorkspaceCreated.find_by_legacy_id(row['id'])
          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
        end
        rows.count.should > 0
        Events::PublicWorkspaceCreated.count.should == rows.count
      end

      it "copies PRIVATE WORKSPACE CREATED data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed INNER JOIN
        legacy_migrate.edc_workspace as ew  ON ew.id = ed.entity_id and ew.is_public = false where
        type = 'WORKSPACE_CREATED' ;")
        rows.each do |row|
          event = Events::PrivateWorkspaceCreated.find_by_legacy_id(row['id'])
          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
        end
        rows.count.should > 0 
        Events::PrivateWorkspaceCreated.count.should == rows.count
      end

      it "copied WORKSPACE_ARCHIVED data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed  where
        type = 'WORKSPACE_ARCHIVED' ;")
        rows.each do |row|
          event = Events::WorkspaceArchived.find_by_legacy_id(row['id'])
          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
        end
        rows.count.should > 0 
        Events::WorkspaceArchived.count.should == rows.count
      end

      it "copied WORKSPACE_DELETED data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed  where
        type = 'WORKSPACE_DELETED' ;")
        rows.each do |row|
          event = Events::WorkspaceDeleted.find_by_legacy_id(row['id'])
          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
        end
        rows.count.should > 0 
        Events::WorkspaceDeleted.count.should == rows.count
      end

      it "copied WORKSPACE_UNARCHIVED data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed  where
        type = 'WORKSPACE_UNARCHIVED' ;")
        rows.each do |row|
          event = Events::WorkspaceUnarchived.find_by_legacy_id(row['id'])
          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
        end
        rows.count.should > 0 
        Events::WorkspaceUnarchived.count.should == rows.count
      end

      it "copies WORKSPACE MAKE PUBLIC data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed  where
        type = 'WORKSPACE_MAKE_PUBLIC' ;")
        rows.each do |row|
          event = Events::WorkspaceMakePublic.find_by_legacy_id(row['id'])
          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
        end
        rows.count.should > 0 
        Events::WorkspaceMakePublic.count.should == rows.count
      end

      it "copies WORKSPACE MAKE PRIVATE data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed  where
        type = 'WORKSPACE_MAKE_PRIVATE' ;")
        rows.each do |row|
          event = Events::WorkspaceMakePrivate.find_by_legacy_id(row['id'])
          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
        end
        rows.count.should > 0 
        Events::WorkspaceMakePrivate.count.should == rows.count
      end

      it "copies WORKFILE CREATED data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_id as workfile_id from legacy_migrate.edc_activity_stream ed LEFT JOIN
        legacy_migrate.edc_activity_stream_object as aso  ON aso.activity_stream_id = ed.id and aso.entity_type = 'workfile' where
        type = 'WORKFILE_CREATED' ;")
        rows.each do |row|
          event = Events::WorkfileCreated.find_by_legacy_id(row['id'])
          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
          Workfile.unscoped.find_by_id(event.target1_id).legacy_id.should == row['workfile_id']
        end
        rows.count.should > 0 
        Events::WorkfileCreated.count.should == rows.count
      end

      it "copies INSTANCE CREATED (greenplum) data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed
        INNER JOIN legacy_migrate.edc_instance ei ON ei.id = ed.entity_id and ei.instance_provider = 'Greenplum Database'
        where  type = 'INSTANCE_CREATED' ;")
        rows.each do |row|
          event = Events::GreenplumInstanceCreated.find_by_legacy_id(row['id'])
          event.workspace.should be_blank
          event.actor.username.should == row["author"]
          event.gpdb_instance.legacy_id.should == row['entity_id']
        end
        rows.count.should > 0 
        Events::GreenplumInstanceCreated.count.should == rows.count
      end

      it "copies INSTANCE CREATED (hadoop) data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed
        INNER JOIN legacy_migrate.edc_instance ei ON ei.id = ed.entity_id and ei.instance_provider = 'Hadoop'
        where  type = 'INSTANCE_CREATED' ;")
        rows.each do |row|
          event = Events::HadoopInstanceCreated.find_by_legacy_id(row['id'])

          event.workspace.should be_blank
          event.actor.username.should == row["author"]
          event.hadoop_instance.legacy_id.should == row['entity_id']
        end
        rows.count.should > 0 
        Events::HadoopInstanceCreated.count.should == rows.count
      end

      it "copies USER ADDED data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed
         where  type = 'USER_ADDED';")
        rows.each do |row|
          event = Events::UserAdded.find_by_legacy_id(row['id'])
          event.actor.username.should == row["author"]
          event.new_user.legacy_id.should == row['entity_id']
        end
        rows.count.should > 0 
        Events::UserAdded.count.should == rows.count
      end

      it "copies MEMBERS ADDED data fields from the legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.*, count(aso) AS count from legacy_migrate.edc_activity_stream ed
        LEFT JOIN legacy_migrate.edc_activity_stream_object aso ON aso.activity_stream_id = ed.id and aso.object_type = 'object'
         where  type = 'MEMBERS_ADDED' GROUP BY ed.id;")
        rows.each do |row|
          event = Events::MembersAdded.find_by_legacy_id(row['id'])
          event.actor.username.should == row["author"]
          event.num_added.should == row['count'].to_s
        end
        rows.count.should > 0
        Events::MembersAdded.count.should == rows.count
      end

      it "copies PROVISIONING_FAIL from legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed
          where  type = 'PROVISIONING_FAIL';")
        rows.each do |row|
          event = Events::ProvisioningFail.find_by_legacy_id(row['id'])
          event.actor.username.should == row["author"]
          event.workspace.should be_blank
          event.gpdb_instance.legacy_id.should == row['entity_id']
          event.additional_data['error_message'].should == nil
        end
        rows.count.should > 0 
        Events::ProvisioningFail.count.should == rows.count
      end

      it "copies PROVISIONING_SUCCESS from legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.* from legacy_migrate.edc_activity_stream ed
          where  type = 'PROVISIONING_SUCCESS';")
        rows.each do |row|
          event = Events::ProvisioningSuccess.find_by_legacy_id(row['id'])
          event.actor.username.should == row["author"]
          event.workspace.should be_blank
          event.gpdb_instance.legacy_id.should == row['entity_id']
          event.additional_data['error_message'].should == nil
        end
        rows.count.should > 0 
        Events::ProvisioningSuccess.count.should == rows.count
      end

      it "copies WORKFILE UPGRADED VERSION from legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_id as version_num, aso2.object_id as workfile_id, ewv.commit_message as commit_message from legacy_migrate.edc_activity_stream ed
          LEFT JOIN legacy_migrate.edc_activity_stream_object aso ON aso.activity_stream_id = ed.id AND aso.entity_type = 'version'
          LEFT JOIN legacy_migrate.edc_activity_stream_object aso2 ON aso2.activity_stream_id = ed.id AND aso2.entity_type = 'workfile'
          LEFT JOIN legacy_migrate.edc_workfile_version ewv ON ewv.workfile_id = aso2.object_id AND ewv.version_num =aso.object_id ::integer
          where  type = 'WORKFILE_UPGRADED_VERSION';")
        rows.each do |row|
          event = Events::WorkfileUpgradedVersion.find_by_legacy_id(row["id"])

          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
          Workfile.unscoped.find_by_id(event.target1_id).legacy_id.should == row['workfile_id']
          event.additional_data['version_num'].should == row['version_num']
          event.additional_data['commit_message'].should == row['commit_message']
        end
        rows.count.should > 0 
        Events::WorkfileUpgradedVersion.count.should == rows.count
      end

      it "copies WORKFILE_VERSION_DELETED from legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_id as version_num, aso2.object_id as workfile_id, ewv.commit_message as commit_message from legacy_migrate.edc_activity_stream ed
          LEFT JOIN legacy_migrate.edc_activity_stream_object aso ON aso.activity_stream_id = ed.id AND aso.entity_type = 'version'
          LEFT JOIN legacy_migrate.edc_activity_stream_object aso2 ON aso2.activity_stream_id = ed.id AND aso2.entity_type = 'workfile'
          LEFT JOIN legacy_migrate.edc_workfile_version ewv ON ewv.workfile_id = aso2.object_id AND ewv.version_num =aso.object_id ::integer
          where  type = 'WORKFILE_VERSION_DELETED';")
        rows.each do |row|
          event = Events::WorkfileVersionDeleted.find_by_legacy_id(row["id"])

          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
          Workfile.unscoped.find_by_id(event.target1_id).legacy_id.should == row['workfile_id']
          event.additional_data['version_num'].should == row['version_num']
        end
        rows.count.should > 0 
        Events::WorkfileVersionDeleted.count.should == rows.count
      end

      it "copies WORKSPACE CHANGE NAME from legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_name as workspace_old_name FROM legacy_migrate.edc_activity_stream ed
          LEFT JOIN legacy_migrate.edc_activity_stream_object aso ON aso.activity_stream_id = ed.id AND aso.object_type = 'object'
          where  type = 'WORKSPACE_CHANGE_NAME';")
        rows.each do |row|
          event = Events::WorkspaceChangeName.find_by_legacy_id(row["id"])

          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
          event.additional_data['workspace_old_name'].should == row['workspace_old_name']
        end
        rows.count.should > 0 
        Events::WorkspaceChangeName.count.should == rows.count
      end

      it "copies WORKSPACE_ADD_SANDBOX from legacy activity" do
        rows = Legacy.connection.select_all("SELECT ed.*, aso.object_name as workspace_old_name FROM legacy_migrate.edc_activity_stream ed
          LEFT JOIN legacy_migrate.edc_activity_stream_object aso ON aso.activity_stream_id = ed.id AND aso.object_type = 'object'
          where  type = 'WORKSPACE_ADD_SANDBOX';")
        rows.each do |row|
          event = Events::WorkspaceAddSandbox.find_by_legacy_id(row["id"])

          Workspace.unscoped.find(event.workspace_id).legacy_id.should == row['workspace_id']
          event.actor.username.should == row["author"]
        end
        rows.count.should > 0 
        Events::WorkspaceAddSandbox.count.should == rows.count
      end
    end

    it "should create activities" do
      Activity.count.should > 0
    end
  end
end
