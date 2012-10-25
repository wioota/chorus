class InOrderEventMigrator < AbstractMigrator
  class << self
    def migrate(options)
      Legacy.connection.exec_query("DROP TABLE IF EXISTS temp_events;")
      Legacy.connection.exec_query("CREATE TABLE temp_events (LIKE events INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES);")

      new_options = options.merge(:event_table => "temp_events")
      ActivityMigrator.migrate(new_options)
      NoteMigrator.migrate(new_options)

      columns = Events::Base.column_names - ["id"]

      Legacy.connection.exec_query(<<-SQL)
      INSERT INTO events (#{columns.join(',')})
       (select #{columns.map{|col| "temp_events.#{col}"}.join(',')}
         from temp_events
         left outer join events on (temp_events.legacy_type = events.legacy_type AND temp_events.legacy_id = events.legacy_id)
         where events.id is null
         order by created_at asc);
      SQL
      Legacy.connection.exec_query("DROP TABLE temp_events;")
    end

    def classes_to_validate
      []
    end

  end
end