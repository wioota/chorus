class GpdbDataSource < DataSource
  has_many :databases, :class_name => 'GpdbDatabase', :dependent => :destroy, :foreign_key => "data_source_id"
  has_many :datasets, :through => :schemas
  has_many :schemas, :through => :databases, :class_name => 'GpdbSchema'
  has_many :workspaces, :through => :schemas, :foreign_key => 'sandbox_id'

  after_update :create_instance_name_changed_event, :if => :current_user

  def self.create_for_user(user, data_source_hash)
    user.gpdb_data_sources.create!(data_source_hash, :as => :create)
  end

  def self.owned_by(user)
    if user.admin?
      scoped
    else
      where(:owner_id => user.id)
    end
  end

  def used_by_workspaces(viewing_user)
    workspaces.includes({:sandbox => {:database => :data_source }}, :owner).workspaces_for(viewing_user).order("lower(workspaces.name)")
  end

  def connect_with(account, options = {})
    params = {
        :username => account.db_username,
        :password => account.db_password,
        :host => host,
        :port => port,
        :database => db_name,
        :logger => Rails.logger
    }.merge(options)

    connection = GreenplumConnection.new params

    if block_given?
      connection.with_connection do
        yield connection
      end
    else
      connection
    end
  end

  def create_database(name, current_user)
    new_db = GpdbDatabase.new(:name => name, :data_source => self)
    raise ActiveRecord::RecordInvalid.new(new_db) unless new_db.valid?

    connect_as(current_user).create_database(name)
    refresh_databases
    databases.find_by_name!(name)
  end

  def refresh_databases(options ={})
    found_databases = []
    rows = connect_with(owner_account).prepare_and_execute_statement(database_and_role_sql).hashes
    database_account_groups = rows.inject({}) do |groups, row|
      groups[row["database_name"]] ||= []
      groups[row["database_name"]] << row["db_username"]
      groups
    end

    database_account_groups.each do |database_name, db_usernames|
      database = databases.find_or_initialize_by_name(database_name)

      if database.invalid?
        databases.delete(database)
        next
      end

      database.update_attributes!({:stale_at => nil}, :without_protection => true)
      database_accounts = accounts.where(:db_username => db_usernames)
      if database.instance_accounts.sort != database_accounts.sort
        database.instance_accounts = database_accounts
        QC.enqueue_if_not_queued("GpdbDatabase.reindex_datasets", database.id) if database.datasets.count > 0
      end
      found_databases << database
    end
    refresh_schemas options unless options[:skip_schema_refresh]
  rescue GreenplumConnection::QueryError => e
    Chorus.log_error "Could not refresh database: #{e.message} on #{e.backtrace[0]}"
  ensure
    if options[:mark_stale]
      (databases.not_stale - found_databases).each(&:mark_stale!)
    end
  end

  def refresh_schemas(options={})
    databases.each do |database|
      begin
        Schema.refresh(owner_account, database, options.reverse_merge(:refresh_all => true))
      rescue GreenplumConnection::DatabaseError => e
        Chorus.log_error "Could not refresh database #{database.name}: #{e.message} #{e.backtrace.to_s}"
      end
    end
  end

  def entity_type_name
    'gpdb_data_source'
  end

  def instance_provider
    "Greenplum Database"
  end

  private

  def account_names
    accounts.pluck(:db_username)
  end

  def database_and_role_sql
    roles = Arel::Table.new("pg_catalog.pg_roles", :as => "r")
    databases = Arel::Table.new("pg_catalog.pg_database", :as => "d")

    roles.join(databases).
        on(Arel.sql("has_database_privilege(r.oid, d.oid, 'CONNECT')")).
        where(
        databases[:datname].not_eq("postgres").
            and(databases[:datistemplate].eq(false)).
            and(databases[:datallowconn].eq(true)).
            and(roles[:rolname].in(account_names))
    ).project(
        roles[:rolname].as("db_username"),
        databases[:datname].as("database_name")
    ).to_sql
  end

  def create_instance_name_changed_event
    if name_changed?
      Events::GreenplumInstanceChangedName.by(current_user).add(
          :gpdb_data_source => self,
          :old_name => name_was,
          :new_name => name
      )
    end
  end
end
