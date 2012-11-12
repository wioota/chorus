require 'legacy_migration_spec_helper'

describe ImportScheduleMigrator do
  def dt(s)
    DateTime.parse(s + " " + Time.now.zone.to_s).utc
  end

  def d(s)
    Date.parse(s)
  end

  def int_to_frequency(i)
    case i
      when 4
        'daily'
      when 5
        'weekly'
      when 6
        'monthly'
    end
  end

  describe ".migrate" do
    let(:current_time) { Time.current }

    before :all do
      Timecop.freeze(current_time) do
        ImportScheduleMigrator.migrate
      end
    end

    describe "copying the data" do
      it "creates new instances for legacy import schedules and is idempotent" do
        count = Legacy.connection.select_all("Select count(*) from legacy_migrate.edc_import_schedule").first["count"]
        count.should > 0
        ImportSchedule.count.should == count
        ImportScheduleMigrator.migrate
        ImportSchedule.count.should == count
      end

      it "copies the correct data fields from the legacy import schedule" do
        Legacy.connection.select_all("Select eis.* , ei.sample_count, ei.truncate, ei.workspace_id, ei.to_table,
          ei.owner_id,ei.source_id,d.id AS dataset_id from legacy_migrate.edc_import_schedule eis INNER JOIN
          legacy_migrate.edc_import ei ON ei.schedule_id = eis.id INNER JOIN datasets d ON d.legacy_id = normalize_key(ei.source_id)").each do |row|
          import_schedule = ImportSchedule.unscoped.find_by_legacy_id(row['id'])
          import_schedule.start_datetime.should == dt(row["start_time"])
          import_schedule.end_date.should == d(row["end_time"])
          import_schedule.frequency.should == int_to_frequency(row['frequency'])

          if row['job_name'].nil?
            import_schedule.deleted_at.should == dt(row['last_updated_tx_stamp'])
          else
            import_schedule.deleted_at.should be_nil
          end
          import_schedule.updated_at.should == dt(row['last_updated_tx_stamp'])
          import_schedule.created_at.should == dt(row['created_tx_stamp'])
          import_schedule.workspace.should == Workspace.unscoped.find_by_legacy_id(row['workspace_id'])
          import_schedule.to_table.should == row['to_table']
          row['source_id'].should include(import_schedule.source_dataset.name)
          import_schedule.truncate.should == (row["truncate"] =="t")
          import_schedule.user.legacy_id.should == row["owner_id"]
          import_schedule.sample_count.should == row["sample_count"].try(:to_i)
          import_schedule.next_import_at.should == ImportTime.new(
              import_schedule.start_datetime,
              import_schedule.end_date,
              import_schedule.frequency,
              current_time
          ).next_import_time if row['job_name']
          import_schedule.destination_dataset_id.should == row["dataset_id"]
          import_schedule.new_table.should be_nil
        end
      end
    end
  end
end
