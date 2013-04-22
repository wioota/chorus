class OracleDataSource < DataSource
  has_many :schemas, :as => :parent, :class_name => 'OracleSchema', :dependent => :destroy

  def self.create_for_user(user, params)
    user.oracle_data_sources.create!(params) do |data_source|
      data_source.shared = params[:shared]
    end
  end

  def refresh_databases(options={})
    refresh_schemas options
  end

  # Used by search
  def refresh_schemas(options={})
    schema_permissions = update_schemas(options)
    update_permissions(schema_permissions)
    schemas.map(&:name)
  end

  private

  def update_permissions(schema_permissions)
    schema_permissions.each do |schema_id, account_ids|
      schema = schemas.find(schema_id)
      if schema.instance_account_ids.sort != account_ids.sort
        schema.instance_account_ids = account_ids
        schema.save!
        QC.enqueue_if_not_queued("OracleSchema.reindex_datasets", schema.id)
      end
    end
  end

  def update_schemas(options)
    begin
      schema_permissions = {}
      accounts.each do |account|
        begin
          schemas = Schema.refresh(account, self, options.reverse_merge(:refresh_all => true))
          schemas.each do |schema|
            schema_permissions[schema.id] ||= []
            schema_permissions[schema.id] << account.id
          end
        rescue OracleConnection::DatabaseError => e
          Chorus.log_debug "Could not refresh schemas for Oracle account #{account.id}: #{e.error_type} #{e.message} #{e.backtrace.to_s}"
        end
      end
    rescue => e
      Chorus.log_error "Error refreshing Oracle Schema #{e.message}"
    end
    schema_permissions
  end

  def connection_class
    OracleConnection
  end
end
