require 'legacy_migration_spec_helper'

describe WorkfileMigrator do
  describe ".migrate" do
    def should_be_equal_dates(date1, date2_str)
      date1.should == DateTime.parse(date2_str)
    end

    describe "validate the number of entries copied" do
      it "creates a workfile for every legacy workfile, including deleted ones" do
        legacy_workfiles = Legacy.connection.select_all("select * from edc_work_file")
        Workfile.unscoped.count.should == legacy_workfiles.length
      end

      it "creates a workfile draft for every legacy draft, including deleted ones" do
        legacy_drafts = Legacy.connection.select_all("select * from edc_workfile_draft WHERE is_deleted = 'f'")
        WorkfileDraft.count.should == legacy_drafts.length
      end

      it "creates a workfile version for every legacy version, including deleted ones" do
        legacy_versions = Legacy.connection.select_all("select * from edc_workfile_version")
        WorkfileVersion.unscoped.count.should == legacy_versions.length
      end
    end

    describe "copying the data" do
      before :each do
        @legacy_workfiles = Legacy.connection.select_all("select wf.* from edc_work_file wf, edc_workspace ws where wf.workspace_id = ws.id AND ws.is_deleted = 'f';")
        @legacy_drafts = Legacy.connection.select_all("select * from edc_workfile_draft WHERE is_deleted = 'f'")
        @legacy_versions = Legacy.connection.select_all("select * from edc_workfile_version")
      end

      it "associates new workfiles with the appropriate workspace" do
        @legacy_workfiles.each do |legacy_workfile|
          legacy_workspace = Legacy.connection.select_one("select * from edc_workspace where id = '#{legacy_workfile["workspace_id"]}'")
          new_workfile = Workfile.unscoped.find_by_legacy_id(legacy_workfile["id"])
          Workspace.unscoped.find_by_id(new_workfile.workspace_id).legacy_id.should == legacy_workspace["id"]
        end
      end

      it "associates new workfiles with the appropriate owner" do
        @legacy_workfiles.each do |legacy_workfile|
          legacy_owner = Legacy.connection.select_one("select * from edc_user where user_name = '#{legacy_workfile["owner"]}'")
          new_workfile = Workfile.unscoped.find_by_legacy_id(legacy_workfile["id"])
          new_workfile.owner.legacy_id.should == legacy_owner["id"]
        end
      end

      it "copies the interesting fields" do
        @legacy_workfiles.each do |legacy_workfile|
          new_workfile = Workfile.unscoped.find_by_legacy_id(legacy_workfile["id"])
          new_workfile.description.should == legacy_workfile["description"]
          new_workfile.file_name.should == legacy_workfile["file_name"]
          should_be_equal_dates(new_workfile.created_at, legacy_workfile["created_tx_stamp"])
          should_be_equal_dates(new_workfile.updated_at, legacy_workfile["last_updated_tx_stamp"])
        end
      end

      it 'sets the last workfile schema id' do
        @legacy_workfiles.each do |legacy_workfile|
          new_workfile = Workfile.unscoped.find_by_legacy_id(legacy_workfile["id"])
          last_execution_task = Legacy.connection.select_one <<-SQL
            SELECT edc_task.id AS task_id, edc_task.instance_id AS instance_id, edc_database.name AS database_name, edc_schema.name AS schema_name
              FROM edc_task
            INNER JOIN edc_database ON edc_database.id=edc_task.database_id
            INNER JOIN edc_schema ON edc_schema.id=edc_task.schema_id
            WHERE edc_task.task_type='WORKFILE_SQL_EXECUTION' AND edc_task.entity_id='#{legacy_workfile["id"]}'
            ORDER BY edc_task.created_stamp DESC
          SQL
          if last_execution_task
            last_execution_instance = GpdbInstance.find_by_legacy_id(last_execution_task['instance_id'])
            last_execution_database = last_execution_instance.databases.find_by_name(last_execution_task['database_name'])
            last_execution_schema = last_execution_database.schemas.find_by_name(last_execution_task['schema_name'])

            new_workfile.execution_schema.should == last_execution_schema
          else
            new_workfile.execution_schema_id.should be_nil
          end
        end
      end

      it "copies the deleted flag" do
        @legacy_workfiles.each do |legacy_workfile|
          new_workfile = Workfile.unscoped.find_by_legacy_id(legacy_workfile["id"])
          if legacy_workfile["is_deleted"] == 't'
            should_be_equal_dates(new_workfile.deleted_at, legacy_workfile["last_updated_tx_stamp"])
          elsif legacy_workfile["is_deleted"] == 'f'
            new_workfile.deleted_at.should be_nil
          else
            fail "Unrecognized workfile state"
          end
        end
      end

      describe "versions" do
        it "migrates all versions from the legacy database" do
          @legacy_workfiles.each do |legacy_workfile|
            new_workfile = Workfile.unscoped.find_by_legacy_id(legacy_workfile["id"])
            legacy_versions = Legacy.connection.select_all("select * from edc_workfile_version WHERE workfile_id = '#{legacy_workfile["id"]}'")
            new_workfile.versions.count.should == legacy_versions.length
          end
        end

        it "associates new versions with the appropriate workfile" do
          @legacy_versions.each do |legacy_version|
            legacy_workfile = Legacy.connection.select_one("select * from edc_work_file where id = '#{legacy_version["workfile_id"]}'")
            new_workfile = Workfile.unscoped.find_by_legacy_id(legacy_workfile["id"])
            new_version = WorkfileVersion.find_by_legacy_id(legacy_version["id"])
            new_workfile.legacy_id.should == legacy_workfile["id"]
          end
        end

        it "associates the new version with the appropriate owner and modifier" do
          @legacy_versions.each do |legacy_version|
            legacy_owner = Legacy.connection.select_one("select * from edc_user where user_name = '#{legacy_version["version_owner"]}'")
            legacy_modifier = Legacy.connection.select_one("select * from edc_user where user_name = '#{legacy_version["modified_by"]}'")

            new_owner = User.unscoped.find_by_legacy_id(legacy_owner["id"])
            new_modifier = User.unscoped.find_by_legacy_id(legacy_modifier["id"])

            new_version = WorkfileVersion.find_by_legacy_id(legacy_version["id"])

            new_version.owner_id.should == new_owner.id
            new_version.modifier_id.should == new_modifier.id
          end
        end

        it "copies the interesting fields" do
          @legacy_versions.each do |legacy_version|
            new_version = WorkfileVersion.find_by_legacy_id(legacy_version["id"])
            new_version.commit_message.should == legacy_version["commit_message"]
            new_version.version_num.should == legacy_version["version_num"].to_i
            should_be_equal_dates(new_version.created_at, legacy_version["created_tx_stamp"])
            should_be_equal_dates(new_version.updated_at, legacy_version["last_updated_tx_stamp"])
          end
        end

        it "attaches the legacy workfile version content to the new workfile version model" do
          @legacy_versions.each do |legacy_version|
            new_version = WorkfileVersion.find_by_legacy_id(legacy_version["id"])
            new_version.contents_file_name.should == Workfile.unscoped.find(new_version.workfile_id).file_name
          end
        end

        it "should associate the latest version" do
          @legacy_workfiles.each do |legacy_workfile|
            new_workfile = Workfile.unscoped.find_by_legacy_id(legacy_workfile["id"])
            legacy_latest_version_sql = <<-SQL
SELECT edc_workfile_version.id
FROM edc_workfile_version
JOIN edc_work_file on edc_work_file.latest_version_num = edc_workfile_version.version_num
     AND edc_work_file.id = edc_workfile_version.workfile_id
WHERE edc_work_file.id = '#{legacy_workfile["id"]}'
            SQL
            legacy_version_id = Legacy.connection.select_value(legacy_latest_version_sql)
            latest_version = WorkfileVersion.find_by_legacy_id(legacy_version_id)
            new_workfile.latest_workfile_version.should == latest_version
          end
        end

        it "should cache content type from the latest version" do
          @legacy_workfiles.each do |legacy_workfile|
            new_workfile = Workfile.unscoped.find_by_legacy_id(legacy_workfile["id"])
            new_workfile.content_type.should == new_workfile.latest_workfile_version.file_type
          end
        end
      end

      describe "draft" do
        it "migrates non-deleted drafts" do
          @legacy_workfiles.each do |legacy_workfile|
            new_workfile = Workfile.unscoped.find_by_legacy_id(legacy_workfile["id"])
            legacy_drafts = Legacy.connection.select_all("select * from edc_workfile_draft WHERE workfile_id = '#{legacy_workfile["id"]}' AND is_deleted = 'f'")
            new_workfile.drafts.count.should == legacy_drafts.length
          end
        end

        it "associates new drafts with the appropriate workfile" do
          @legacy_drafts.each do |legacy_draft|
            legacy_workfile = Legacy.connection.select_one("select * from edc_work_file where id = '#{legacy_draft["workfile_id"]}'")
            new_draft = WorkfileDraft.find_by_legacy_id(legacy_draft["id"])
            new_draft.workfile.legacy_id.should == legacy_workfile["id"]
          end
        end

        it "associates the new draft with the appropriate owner" do
          @legacy_drafts.each do |legacy_draft|
            legacy_owner = Legacy.connection.select_one("select * from edc_user where user_name = '#{legacy_draft["draft_owner"]}'")
            new_owner = User.unscoped.find_by_legacy_id(legacy_owner["id"])
            new_draft = WorkfileDraft.find_by_legacy_id(legacy_draft["id"])
            new_draft.owner_id.should == new_owner.id
          end
        end

        it "copies the interesting fields" do
          @legacy_drafts.each do |legacy_draft|
            new_draft = WorkfileDraft.find_by_legacy_id(legacy_draft["id"])
            new_draft.base_version.should == legacy_draft["base_version_num"].to_i
            should_be_equal_dates(new_draft.created_at, legacy_draft["created_tx_stamp"])
            should_be_equal_dates(new_draft.updated_at, legacy_draft["last_updated_tx_stamp"])
          end
        end

        it "attaches the legacy workfile draft content to the new workfile draft model" do
          @legacy_drafts.each do |legacy_draft|
            new_draft = WorkfileDraft.find_by_legacy_id(legacy_draft["id"])
            new_draft.content.should be_present
          end
        end
      end
    end
  end
end
