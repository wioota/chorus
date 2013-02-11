require 'stale'

class GpdbDataset < Dataset
  has_many :tableau_workbook_publications, :dependent => :destroy, :foreign_key => :dataset_id
  delegate :definition, :to => :statistics

  has_many :import_schedules, :foreign_key => 'source_dataset_id', :dependent => :destroy
  has_many :imports, :foreign_key => 'source_dataset_id'

  delegate :connect_with, :to => :schema

  def instance_account_ids
    schema.database.instance_account_ids
  end

  def found_in_workspace_id
    (bound_workspace_ids + schema.workspace_ids).uniq
  end

  def self.total_entries(account, schema, options = {})
    schema.dataset_count account, options
  end

  def self.refresh(account, schema, options = {})
    schema.refresh_datasets account, options
  end

  def self.visible_to(*args)
    refresh(*args)
  end

  def source_dataset_for(workspace)
    schema_id != workspace.sandbox_id
  end

  def check_duplicate_column(user)
    true
  end

  def add_metadata!(account)
    @statistics = DatasetStatistics.for_dataset(self, account)
  end

  def database_name
    schema.database.name
  end

  def table_description
    DatasetStatistics.for_dataset(self, schema.database.data_source.owner_account).description
  rescue
    nil
  end

  def schema_name
    schema.name
  end

  def column_name
    column_data.map(&:name)
  end

  def column_description
    column_data.map(&:description).compact
  end

  def column_data
    @column_data ||= DatasetColumn.columns_for(schema.database.data_source.owner_account, self)
  end

  def query_setup_sql
    ""
  end

  def scoped_name
    %Q{"#{schema_name}"."#{name}"}
  end

  def dataset_consistent?(another_dataset)
    another_column_data = another_dataset.column_data
    my_column_data = column_data

    consistent_size = my_column_data.size == another_column_data.size

    consistent_size && my_column_data.all? do |column|
      another_column = another_column_data.find do |another_column|
        another_column.name == column.name
      end

      another_column && another_column.data_type == column.data_type
    end
  end

  def preview_sql
    all_rows_sql
  end

  def all_rows_sql(limit = nil)
    Arel::Table.new(name).project('*').take(limit).to_sql
  end

  class Query
    def initialize(schema)
      @schema = schema
    end

    attr_reader :schema

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
      schema_ids = SCHEMAS.where(SCHEMAS[:nspname].eq(schema.name)).project(:oid)
      RELATIONS.where(RELATIONS[:relnamespace].in(schema_ids))
    end

    def metadata_for_dataset(table_name)
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
          (PARTITIONS.where(PARTITIONS[:schemaname].eq(schema.name).
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

    def partition_data_for_dataset(table_name)
      PARTITIONS.where(PARTITIONS[:tablename].eq(table_name).
          and(PARTITIONS[:schemaname].eq(schema.name))).project(
          Arel.sql('sum(pg_total_relation_size(partitiontablename))').as('disk_size')
      )
    end
  end

  def query_results(account, query_method)
    statement = Query.new(schema).send(query_method, name).to_sql
    results = schema.connect_with(account).prepare_and_execute_statement(statement)
    results.hashes.first
  end

  def as_sequel
    Sequel.qualify(schema.name, name)
  end

  private

  def create_import_event(params, user)
    workspace = Workspace.find(params[:workspace_id])
    dst_table = workspace.sandbox.datasets.find_by_name(params[:to_table]) unless params[:new_table].to_s == "true"
    Events::DatasetImportCreated.by(user).add(
        :workspace => workspace,
        :source_dataset => self,
        :dataset => dst_table,
        :destination_table => params[:to_table]
    )
  end

  def update_counter_cache
    if changed_attributes.include?('stale_at')
      if stale?
        GpdbSchema.decrement_counter(:active_tables_and_views_count, schema_id)
      else
        GpdbSchema.increment_counter(:active_tables_and_views_count, schema_id)
      end
    end
  end
end

