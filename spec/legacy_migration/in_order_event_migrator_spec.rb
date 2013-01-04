require 'legacy_migration_spec_helper'

describe InOrderEventMigrator do
  describe ".migrate" do
    def select_legacy_values(key, sql)
      Legacy.connection.select_all(sql).map{ |val| val[key.to_s] }
    end

    def legacy_keys(ids, type)
      ids.map { |id| {:legacy_id => id}.merge :legacy_type => type }
    end

    it "inserts the event objects in created_at order" do
      #TODO: a large portion of this filtering should go away when we correctly migrate imports from chorus views story 38441081
      NOT_YET_IMPLEMENTED_EVENTS = %w(INSTANCE_DELETED WORKSPACE_ADD_TABLE)
      IGNORED_EVENTS = %w(START_PROVISIONING PROVISIONING_SUCCESS PROVISIONING_FAIL)
      NOT_SUPPORTED_IN_2_2_EVENTS = %w(MEMBERS_DELETED)
      IMPORT_EVENTS = %w(IMPORT_CREATED IMPORT_SUCCESS IMPORT_FAILED)
      EXCLUDED_EVENTS = (NOT_YET_IMPLEMENTED_EVENTS + NOT_SUPPORTED_IN_2_2_EVENTS + IMPORT_EVENTS + IGNORED_EVENTS).map { |ev| "'#{ev}'" }.join(', ')

      activities = select_legacy_values(:id, <<-SQL)
      SELECT id
      FROM legacy_migrate.edc_activity_stream
      WHERE type NOT IN (#{EXCLUDED_EVENTS});
      SQL

      import_events = IMPORT_EVENTS.map do |event|
        dataset_events = select_legacy_values(:id, <<-SQL)
        SELECT ed.id
        FROM legacy_migrate.edc_activity_stream ed
        LEFT JOIN legacy_migrate.edc_activity_stream_object as source_dataset_aso
              ON ed.id = source_dataset_aso.activity_stream_id and source_dataset_aso.entity_type IN ('databaseObject', 'chrousView')
        WHERE type = '#{event}' and indirect_verb = 'of dataset';
        SQL
        non_dataset_events = select_legacy_values(:id, <<-SQL)
        SELECT id
        FROM legacy_migrate.edc_activity_stream
        WHERE type = '#{event}' and indirect_verb != 'of dataset';
        SQL
        non_dataset_events + dataset_events
      end.flatten

      comments = select_legacy_values(:id, <<-SQL)
      SELECT id
      FROM legacy_migrate.edc_comment
      WHERE entity_type NOT IN ('comment', 'activitystream');
      SQL

      all_events = legacy_keys(comments, 'edc_comment')
      all_events += legacy_keys(activities + import_events, 'edc_activity_stream')

      Events::Base.unscoped.map {|e| e.attributes.symbolize_keys.slice(:legacy_id, :legacy_type) }.should =~ all_events

      id_order = Events::Base.unscoped.order(:id).pluck(:id)
      created_order = Events::Base.unscoped.order("created_at, id").pluck(:id)

			id_order.should == created_order

      expect { Legacy.connection.select_value("SELECT 1 from temp_events;") }.to raise_exception()
    end
  end
end
