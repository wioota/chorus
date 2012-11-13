require 'legacy_migration_spec_helper'

describe InOrderEventMigrator do
  describe ".migrate" do
    it "inserts the event objects in created_at order" do
      #TODO: a large portion of this filtering should go away when we correctly migrate imports from chorus views story 38441081
      not_yet_implemented_events = %w(INSTANCE_DELETED WORKSPACE_ADD_HDFS_AS_EXT_TABLE WORKSPACE_ADD_TABLE)
      not_supported_in_2_2 = %w(MEMBERS_DELETED)
      import_events = %w(IMPORT_CREATED IMPORT_SUCCESS)
      excluded_events = (not_yet_implemented_events + not_supported_in_2_2 + import_events).map { |ev| "'#{ev}'" }.join(', ')

      activity_count = Legacy.connection.select_value(<<-SQL)
      SELECT count(*)
      FROM legacy_migrate.edc_activity_stream
      WHERE type NOT IN (#{excluded_events});
      SQL

      import_event_count = import_events.inject(0) do |count, event|
        dataset_event_count = Legacy.connection.select_value(<<-SQL)
        SELECT count(ed.*)
        FROM legacy_migrate.edc_activity_stream ed
        INNER JOIN legacy_migrate.edc_activity_stream_object as source_dataset_aso
              ON ed.id = source_dataset_aso.activity_stream_id and source_dataset_aso.entity_type = 'databaseObject'
        WHERE type = '#{event}' and indirect_verb = 'of dataset';
        SQL
        non_dataset_event_count = Legacy.connection.select_value(<<-SQL)
        SELECT count(*)
        FROM legacy_migrate.edc_activity_stream
        WHERE type = '#{event}' and indirect_verb != 'of dataset';
        SQL
        non_dataset_event_count + dataset_event_count + count
      end

      comment_count = Legacy.connection.select_value(<<-SQL)
      SELECT count(*)
      FROM legacy_migrate.edc_comment
      WHERE entity_type NOT IN ('comment', 'activitystream');
      SQL

      Events::Base.unscoped.count.should == (comment_count + activity_count + import_event_count)

      id_order = Events::Base.unscoped.order("id").pluck("id")
      created_order = Events::Base.unscoped.order("created_at, id").pluck("id")

			id_order.should == created_order

      expect { Legacy.connection.select_value("SELECT 1 from temp_events;") }.to raise_exception()
    end
  end
end
