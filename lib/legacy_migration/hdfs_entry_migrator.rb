class HdfsEntryMigrator < AbstractMigrator
  class << self
    def prerequisites
      HadoopInstanceMigrator.migrate
    end

    def classes_to_validate
      [
          [HdfsEntry, {:include => :hadoop_instance}]
      ]
    end

    def migrate
      prerequisites

      Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)

      rows = Legacy.connection.select_all(<<-SQL)
          SELECT DISTINCT
            normalize_key(object_id) AS entity_id
          FROM edc_activity_stream_object
          WHERE entity_type = 'hdfs'
            AND NOT normalize_key(object_id) IN (SELECT legacy_id FROM hdfs_entries)
      SQL

      rows.each do |row|
        (legacy_hadoop_instance_id, path) = row["entity_id"].split("|")
        hadoop_instance = HadoopInstance.find_by_legacy_id!(legacy_hadoop_instance_id)

        # use rails in order to split up path into several entries, including an entry with the basename of path
        hadoop_instance.hdfs_entries.create({
          :path => path,
          :legacy_id => row["entity_id"]
        }, :without_protection => true)
      end

      Sunspot.session = Sunspot.session.original_session
    end
  end
end
