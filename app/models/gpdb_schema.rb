class GpdbSchema < ActiveRecord::Base
  include Stale
  SCHEMAS_SQL = <<-SQL
  SELECT
    schemas.nspname as schema_name
  FROM
    pg_namespace schemas
  WHERE
    schemas.nspname NOT LIKE 'pg_%'
    AND schemas.nspname NOT IN ('information_schema', 'gp_toolkit', 'gpperfmon')
  ORDER BY lower(schemas.nspname)
  SQL

  SCHEMA_FUNCTION_QUERY = <<-SQL
      SELECT t1.oid, t1.proname, t1.lanname, t1.rettype, t1.proargnames, (SELECT t2.typname ORDER BY inputtypeid) AS argtypes, t1.prosrc, d.description
        FROM ( SELECT p.oid,p.proname,
           CASE WHEN p.proargtypes='' THEN NULL
               ELSE unnest(p.proargtypes)
               END as inputtype,
           now() AS inputtypeid, p.proargnames, p.prosrc, l.lanname, t.typname AS rettype
         FROM pg_proc p, pg_namespace n, pg_type t, pg_language l
         WHERE p.pronamespace=n.oid
           AND p.prolang=l.oid
           AND p.prorettype = t.oid
           AND n.nspname= '%s') AS t1
      LEFT JOIN pg_type AS t2
      ON t1.inputtype=t2.oid
      LEFT JOIN pg_description AS d ON t1.oid=d.objoid
      ORDER BY t1.oid;
  SQL

  SCHEMA_DISK_SPACE_QUERY = <<-SQL
    SELECT sum(pg_total_relation_size(pg_catalog.pg_class.oid))::bigint AS size
    FROM   pg_catalog.pg_class
    LEFT JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
    WHERE  pg_catalog.pg_namespace.nspname = %s
  SQL

  has_many :workspaces, :inverse_of => :sandbox, :foreign_key => :sandbox_id
  belongs_to :database, :class_name => 'GpdbDatabase'
  has_many :datasets, :foreign_key => :schema_id
  delegate :with_gpdb_connection, :to => :database
  delegate :gpdb_instance, :account_for_user!, :to => :database

  before_save :mark_schemas_as_stale

  def self.refresh(account, database, options = {})
    found_schemas = []

    schema_rows = database.with_gpdb_connection(account) do |conn|
      conn.exec_query(SCHEMAS_SQL)
    end

    schema_rows.each do |row|
      begin
        schema = database.schemas.find_or_initialize_by_name(row["schema_name"])
        found_schemas << schema
        schema_new = schema.new_record?
        if schema_new
          schema.save!
        else
          schema.update_attributes!({:stale_at => nil}, :without_protection => true)
        end
        Dataset.refresh(account, schema, options) if options[:refresh_all]

      rescue ActiveRecord::StatementInvalid => e
      end
    end
    found_schemas
  rescue ActiveRecord::JDBCError, ActiveRecord::StatementInvalid => e
    Chorus.log_error "Could not refresh schemas: #{e.message} on #{e.backtrace[0]}"
    return []
  ensure
    if options[:mark_stale]
      (database.schemas.not_stale - found_schemas).each do |schema|
        schema.stale_at = Time.now
        schema.save!
      end
    end
  end

  def self.visible_to(*args)
    refresh(*args)
  end

  def accessible_to(user)
    database.gpdb_instance.accessible_to(user)
  end

  def self.find_and_verify_in_source(schema_id, user)
    schema = GpdbSchema.find(schema_id)
    schema.verify_in_source(user)
    schema
  rescue
    raise ActiveRecord::RecordNotFound
  end

  def verify_in_source(user)
    account = account_for_user!(user)
    with_gpdb_connection(account) { |conn|}
  end

  def stored_functions(account)
    results = database.with_gpdb_connection(account) do |conn|
      conn.exec_query(SCHEMA_FUNCTION_QUERY % [name, name])
    end

    #This would be a lot easiser if the schema_function_query could use ARRAY_AGG,
    #but it is not available on GPDB 4.0

    reduced_results = results.reduce [-1, []] do |last, result|
      record = result.values
      last_record_id = last[0]
      functions = last[1]
      current_function = functions.last
      current_function_types = current_function[5] if current_function
      arg_type = record[5]


      if current_function and record[0] == last_record_id
        current_function_types << arg_type
      else
        record[5] = [arg_type]
        functions << record
      end

      [record[0], last[1]]
    end

    reduced_results.last.map do |record|
      GpdbSchemaFunction.new(name, *record[1..7])
    end
  end

  def disk_space_used(account)
    if @disk_space_used.nil?
      results = database.with_gpdb_connection(account) do |conn|
        conn.exec_query(SCHEMA_DISK_SPACE_QUERY % [conn.quote(name)])
      end

      @disk_space_used = results.first['size']
    end
    @disk_space_used == :error ? nil : @disk_space_used
  rescue Exception
    @disk_space_used = :error
    nil
  end

  def with_gpdb_connection(account, set_search=true)
    database.with_gpdb_connection(account) do |conn|
      if set_search
        add_schema_to_search_path(conn)
      end
      yield conn
    end
  end

  private

  def add_schema_to_search_path(conn)
    conn.schema_search_path = "#{conn.quote_column_name(name)}, 'public'"
  rescue ActiveRecord::StatementInvalid
    conn.schema_search_path = "#{conn.quote_column_name(name)}"
  end

  def mark_schemas_as_stale
    if stale? && stale_at_changed?
      datasets.each do |dataset|
        dataset.mark_stale! unless dataset.type == "ChorusView"
      end
    end
  end
end
