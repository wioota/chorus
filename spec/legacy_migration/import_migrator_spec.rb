require 'legacy_migration_spec_helper'

describe ImportMigrator do
  describe ".migrate" do
    it "creates new instances for legacy imports and is idempotent" do
      legacy_count = Legacy.connection.select_all("Select count(*) from legacy_migrate.edc_import where schedule_id is null").first["count"]
      expect(Import.count).to be > 0
      expect(Import.count).to eq(legacy_count)
    end

    it "is idempotent" do
      expect {
        ImportMigrator.migrate
      }.not_to change(Import, :count)
    end

    it "copies the correct data fields from the legacy import schedule" do
      Legacy.connection.select_all(<<-SQL
        SELECT
          ei.*,
          normalize_key(ei.source_id) AS normalized_source_id,
          t.state AS task_state,
          t.completed_stamp,
          t.started_stamp
          FROM legacy_migrate.edc_import ei
          LEFT JOIN legacy_migrate.edc_task t ON t.id = ei.latest_task_id
          WHERE ei.schedule_id IS NULL
      SQL
      ).each do |row|
        import = Import.find_by_legacy_id(row['id'])
        expect(import.workspace.legacy_id).to eq(row['workspace_id'])
        expect(import.to_table).to eq(row['to_table'])
        expect(import.sample_count.to_i).to eq(row['sample_count'].to_i)
        expect(import.truncate).to eq(row['truncate'] == "t")
        expect(import.user.legacy_id).to eq(row['owner_id'])
        expect(import.success).to eq(row['task_state'] == 'success')
        expect(import.finished_at).to eq(row['completed_stamp'])
        expect(import.created_at).to eq(row['started_stamp'])

        if row['source_type'] == 'upload_file' # CSV import
          expect(import.source_dataset_id).to be_nil
          expect(import.file_name).to eq row['source_id']
        else # Dataset import
          expect(import.source_dataset.legacy_id).to eq(row['normalized_source_id'])
          expect(import.file_name).to be_nil
        end

        if row['schedule_id']
          import_schedule = ImportSchedule.unscoped.find(import.import_schedule_id)
          expect(import_schedule.legacy_id).to eq(row['schedule_id'])
        else
          expect(import.import_schedule_id).to be_nil
        end

        if import.workspace.sandbox.datasets.find_by_name(row['to_table'])
          expect(import.destination_dataset).not_to be_nil
          expect(import.destination_dataset.name).to eq row['to_table']
          expect(import.destination_dataset.schema_id).to eq import.workspace.sandbox_id
        else
          expect(import.destination_dataset).to be_nil
        end
      end
    end
  end
end

