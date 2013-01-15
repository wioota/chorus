class GpdbInstanceMigrator < AbstractMigrator
  class << self
    def prerequisites
      UserMigrator.migrate
    end

    def classes_to_validate
      [GpdbInstance]
    end

    def migrate
      prerequisites
      Legacy.connection.exec_query("INSERT INTO public.data_sources(
                              legacy_id,
                              name,
                              description,
                              host,
                              port,
                              maintenance_db,
                              owner_id,
                              state,
                              created_at,
                              updated_at,
                              type
                              )
                            SELECT
                              i.id,
                              i.name,
                              i.description,
                              i.host,
                              i.port,
                              i.maintenance_db,
                              u.id,
                              i.state,
                              i.created_tx_stamp,
                              i.last_updated_tx_stamp,
                              'GpdbInstance'
                            FROM edc_instance i
                              INNER JOIN users u
                              ON u.username = i.owner
                            WHERE instance_provider = 'Greenplum Database'
                            AND i.id NOT IN (SELECT legacy_id FROM data_sources);")

    end
  end
end