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

      Legacy.connection.exec_query(
          %Q(
          INSERT INTO hdfs_entries (
              path,
              hadoop_instance_id,
              legacy_id,
              created_at,
              updated_at)
            SELECT DISTINCT
              path,
              instance.id,
              entity_id,
              timestamp,
              timestamp
            FROM (SELECT *,
                    normalize_key(object_id) AS entity_id,
                    split_part(normalize_key(object_id), '|', 1) as hadoop_legacy_id,
                    split_part(normalize_key(object_id), '|', 2) as path,
                    now() as timestamp
                  FROM edc_activity_stream_object) aso
            LEFT JOIN hadoop_instances instance
              ON hadoop_legacy_id = instance.legacy_id
            WHERE entity_type = 'hdfs'
              AND NOT entity_id IN (SELECT legacy_id FROM hdfs_entries))
      )

      Sunspot.session = Sunspot.session.original_session
    end
  end
end
