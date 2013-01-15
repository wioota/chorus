require 'stringio'

class WorkfileMigrator < AbstractMigrator
  class FakeFileUpload < StringIO
    attr_accessor :content_type, :original_filename
  end

  class LegacyFilePath
    def initialize(*args)
      @args = args
    end

    def path
      File.join(@args)
    end
  end

  class << self
    def prerequisites
      UserMigrator.migrate
      WorkspaceMigrator.migrate
      MembershipMigrator.migrate
      DatabaseObjectMigrator.migrate
    end

    def classes_to_validate
      [Workfile, WorkfileVersion, WorkfileDraft]
    end

    def migrate(options = {})
      raise RuntimeError, "Need to have workfile_path set to migrate workfiles" unless options[:workfile_path]
      prerequisites

      Legacy.connection.exec_query <<-SQL
        INSERT INTO public.workfiles(
          legacy_id,
          workspace_id,
          owner_id,
          description,
          created_at,
          file_name,
          updated_at,
          deleted_at
        )
        SELECT
          edc_work_file.id,
          workspace.id,
          owner.id,
          description,
          created_tx_stamp AT TIME ZONE 'UTC',
          file_name,
          last_updated_tx_stamp AT TIME ZONE 'UTC',
          CASE is_deleted
            WHEN 't' THEN last_updated_tx_stamp AT TIME ZONE 'UTC'
            ELSE null
          END
        FROM edc_work_file
        INNER JOIN users owner
          ON owner.username = edc_work_file.owner
        INNER JOIN workspaces workspace
          ON workspace.legacy_id = edc_work_file.workspace_id
        WHERE edc_work_file.id NOT IN (SELECT legacy_id FROM workfiles);
      SQL

      Legacy.connection.exec_query <<-SQL
        UPDATE workfiles
          SET execution_schema_id = (SELECT gpdb_schemas.id FROM gpdb_schemas
          INNER JOIN edc_task ON
            edc_task.entity_id=workfiles.legacy_id
          INNER JOIN data_sources ON
            edc_task.instance_id=data_sources.legacy_id
          INNER JOIN edc_database ON
            edc_database.instance_id=edc_task.instance_id AND edc_database.id=edc_task.database_id
          INNER JOIN gpdb_databases ON
            gpdb_databases.name=edc_database.name AND gpdb_databases.gpdb_instance_id=data_sources.id
          INNER JOIN edc_schema ON
            edc_schema.id=edc_task.schema_id
          WHERE edc_task.task_type='WORKFILE_SQL_EXECUTION'
            AND gpdb_schemas.name=edc_schema.name
            AND gpdb_schemas.database_id=gpdb_databases.id
            ORDER BY edc_task.created_stamp DESC LIMIT 1)
      SQL

      Legacy.connection.exec_query <<-SQL
        INSERT INTO public.workfile_versions(
          legacy_id,
          workfile_id,
          version_num,
          owner_id,
          modifier_id,
          created_at,
          updated_at,
          commit_message
        )
        SELECT
          edc_workfile_version.id,
          workfiles.id,
          version_num,
          owner.id,
          modifier.id,
          created_tx_stamp AT TIME ZONE 'UTC',
          last_updated_tx_stamp AT TIME ZONE 'UTC',
          commit_message
        FROM edc_workfile_version
        INNER JOIN users owner
          ON owner.username = edc_workfile_version.version_owner
        INNER JOIN users modifier
          ON modifier.username = edc_workfile_version.modified_by
        INNER JOIN workfiles
          ON edc_workfile_version.workfile_id = workfiles.legacy_id
        WHERE edc_workfile_version.id NOT IN (SELECT legacy_id FROM workfile_versions);
      SQL

      Legacy.connection.exec_query <<-SQL
        INSERT INTO public.workfile_drafts(
          legacy_id,
          workfile_id,
          base_version,
          owner_id,
          created_at,
          updated_at
        )
        SELECT
          edc_workfile_draft.id,
          workfiles.id,
          base_version_num,
          owner.id,
          created_tx_stamp AT TIME ZONE 'UTC',
          last_updated_tx_stamp AT TIME ZONE 'UTC'
        FROM edc_workfile_draft
        INNER JOIN users owner
          ON owner.username = edc_workfile_draft.draft_owner
        INNER JOIN workfiles
          ON edc_workfile_draft.workfile_id = workfiles.legacy_id
        WHERE is_deleted = 'f'
        AND edc_workfile_draft.id NOT IN (SELECT legacy_id FROM workfile_drafts);
      SQL

      Legacy.connection.exec_query <<-SQL
        UPDATE public.workfiles
          SET latest_workfile_version_id = (SELECT public.workfile_versions.id
            FROM public.workfile_versions
            JOIN edc_workfile_version on public.workfile_versions.legacy_id = edc_workfile_version.id
            JOIN edc_work_file on edc_work_file.latest_version_num = edc_workfile_version.version_num
                 AND edc_work_file.id = edc_workfile_version.workfile_id
            WHERE edc_work_file.id = public.workfiles.legacy_id)
      SQL

      silence_activerecord do
        WorkfileVersion.where("contents_file_name IS NULL").each do |workfile_version|
          workfile = Workfile.find_with_destroyed(workfile_version.workfile_id)
          workfile_updated_at = workfile.updated_at
          row = Legacy.connection.exec_query(<<-SQL
            SELECT
              version_file_id,
              workspace_id,
              file_name,
              mime_type
            FROM edc_workfile_version
            INNER JOIN
              edc_work_file
              ON edc_workfile_version.workfile_id = edc_work_file.id
            WHERE edc_workfile_version.id = '#{workfile_version.legacy_id}';
          SQL
            ).first
          path =  LegacyFilePath.new(options[:workfile_path], "workfile", row["workspace_id"], row["version_file_id"])
          fake_file = FakeFileUpload.new(File.read(path.path))
          fake_file.original_filename = row['file_name']
          fake_file.content_type = row['mime_type']
          fake_file.content_type = 'text/plain' if fake_file.size == 0 # workaround for empty images
          workfile_version.contents = fake_file
          workfile_version.save(:validate => false)
          workfile.update_column :updated_at, workfile_updated_at
        end

        WorkfileDraft.where("content IS NULL").each do |workfile_draft|
          row = Legacy.connection.exec_query("
            SELECT
              draft_file_id,
              workspace_id
            FROM edc_workfile_draft
            INNER JOIN
              edc_work_file
              ON edc_workfile_draft.workfile_id = edc_work_file.id
            WHERE edc_workfile_draft.id = '#{workfile_draft.legacy_id}';
          ").first
          path = LegacyFilePath.new(options[:workfile_path], "workfile", row["workspace_id"], row["draft_file_id"])
          workfile_draft.content = StringIO.new(File.read(path.path))
          workfile_draft.save(:validate => false)
        end

        Workfile.unscoped.where(:content_type => nil).find_each do |wf|
          wf.update_attributes({:content_type => wf.latest_workfile_version.file_type}, :without_protection => true)
        end
      end
    end
  end
end

