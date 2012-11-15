class ImportMigrator < AbstractMigrator
  class << self
    def prerequisites
      ImportScheduleMigrator.migrate
    end

    def classes_to_validate
      [Import]
    end

    def migrate
      prerequisites
      #Explanation for adding the check for schedule_id - For each scheduled import - there is one 'parent' row in import. For each run of schedule import - it creates another row
      #import table which contains proper latest_task_id
      Legacy.connection.exec_query <<-SQL
        INSERT INTO public.imports(
          legacy_id,
          workspace_id,
          source_dataset_id,
          to_table,
          sample_count,
          truncate,
          user_id,
          success,
          import_schedule_id,
          created_at,
          finished_at,
          destination_dataset_id,
          file_name
          )
        SELECT
          i.id,
          w.id,
          d.id,
          i.to_table,
          i.sample_count,
          i.truncate,
          u.id,
          CASE WHEN t.state='success' THEN true ELSE false END,
          s.id,
          t.started_stamp,
          t.completed_stamp,
          dest.id,
          CASE WHEN i.source_type='upload_file' THEN i.source_id ELSE null END
        FROM edc_import i
        LEFT JOIN datasets d
          ON d.legacy_id = normalize_key(i.source_id) AND i.source_type='dataset'
        INNER JOIN users u
          ON u.legacy_id = i.owner_id
        INNER JOIN workspaces w
          ON w.legacy_id = i.workspace_id
        LEFT JOIN edc_task t
          ON t.id = i.latest_task_id
        LEFT JOIN import_schedules s
          ON s.legacy_id = i.schedule_id
        LEFT JOIN datasets dest
          ON dest.name = i.to_table AND dest.schema_id = w.sandbox_id AND dest.type = 'GpdbTable'
        WHERE i.schedule_id IS NULL AND i.id NOT IN (SELECT legacy_id FROM imports);
      SQL
    end
  end
end
