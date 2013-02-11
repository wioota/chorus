class GreenplumMetaDataQuery
  def initialize(schema, table_name)
    @schema = schema
    @table_name = table_name
  end

  attr_reader :schema, :table_name

  VIEWS = Arel::Table.new("pg_views")
  SCHEMAS = Arel::Table.new("pg_namespace")
  RELATIONS = Arel::Table.new("pg_catalog.pg_class")
  PARTITIONS = Arel::Table.new("pg_partitions")
  PARTITION_RULE = Arel::Table.new("pg_partition_rule")
  DESCRIPTIONS = Arel::Table.new("pg_description")
  EXT_TABLES = Arel::Table.new("pg_exttable")
  LAST_OPERATION = Arel::Table.new("pg_stat_last_operation")

  DISK_SIZE = <<-SQL
          CASE WHEN position('''' in pg_catalog.pg_class.relname) > 0 THEN 'unknown'
               WHEN position('\\\\' in pg_catalog.pg_class.relname) > 0 THEN 'unknown'
               ELSE CAST(pg_total_relation_size(pg_catalog.pg_class.oid) AS VARCHAR)
          END
  SQL

  TABLE_TYPE = <<-SQL
          CASE WHEN pg_catalog.pg_class.relhassubclass = 't' THEN 'MASTER_TABLE'
               WHEN pg_catalog.pg_class.relkind = 'v' THEN 'VIEW'
               WHEN pg_exttable.location is NULL THEN 'BASE_TABLE'
               WHEN position('gphdfs' in pg_exttable.location[1]) > 0 THEN 'HD_EXT_TABLE'
               WHEN position('gpfdist' in pg_exttable.location[1]) > 0 THEN 'EXT_TABLE'
               ELSE 'EXT_TABLE'
          END
  SQL

  def relations_in_schema
    schema_ids = SCHEMAS.where(SCHEMAS[:nspname].eq(schema)).project(:oid)
    RELATIONS.where(RELATIONS[:relnamespace].in(schema_ids))
  end

  def partition_data_for_dataset
    PARTITIONS.where(PARTITIONS[:tablename].eq(table_name).
                         and(PARTITIONS[:schemaname].eq(schema))).project(
        Arel.sql('sum(pg_total_relation_size(partitiontablename))').as('disk_size')
    )
  end

  def metadata_query
    relations_in_schema.
        where(RELATIONS[:relname].eq(table_name)).
        join(VIEWS, Arel::Nodes::OuterJoin).
        on(VIEWS[:viewname].eq(RELATIONS[:relname])).
        join(LAST_OPERATION, Arel::Nodes::OuterJoin).
        on(
        LAST_OPERATION[:objid].eq(RELATIONS[:oid]).
            and(LAST_OPERATION[:staactionname].eq('ANALYZE'))
    ).
        join(EXT_TABLES, Arel::Nodes::OuterJoin).
        on(EXT_TABLES[:reloid].eq(RELATIONS[:oid])).
        project(
        (PARTITIONS.where(PARTITIONS[:schemaname].eq(schema).
                              and(PARTITIONS[:tablename].eq(table_name))).
            project(Arel.sql("*").count)
        ).as('partition_count'),
        RELATIONS[:reltuples].as('row_count'),
        RELATIONS[:relname].as('name'),
        Arel.sql("obj_description(pg_catalog.pg_class.oid)").as('description'),
        VIEWS[:definition].as('definition'),
        RELATIONS[:relnatts].as('column_count'),
        LAST_OPERATION[:statime].as('last_analyzed'),
        Arel.sql(DISK_SIZE).as('disk_size'),
        Arel.sql(TABLE_TYPE).as('table_type')
    )
  end
end