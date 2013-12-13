class JdbcConnection < DataSourceConnection
  class DatabaseError < Error; end

  def db_url
    @data_source.url
  end

  def db_options
    super.merge({
      :identifier_output_method => nil,
      :user => @account.db_username,
      :password => @account.db_password
    })
  end

  def connected?
    !!@connection
  end

  def disconnect
    @connection.disconnect if @connection
    @connection = nil
  end

  def version
    with_connection { |connection| connection.version }.slice(0,255)
  end

  def schemas
    with_connection { |connection| connection.schemas }
  end

  def schema_exists?(name)
    schemas.include? name.to_sym
  end

  def table_exists?(name)
    object_exists? :tables, name
  end

  def view_exists?(name)
    object_exists? :views, name
  end

  def datasets(options={})
    with_connection { |connection| connection.tables(:schema_name => schema_name) | connection.views(:schema_name => schema_name) }
  end

  def datasets_count(options={})
    datasets(options).size
  end

  def metadata_for_dataset(dataset_name)
    column_count = with_connection { |connection| connection.schema(dataset_name, {:schema => schema_name}).size }
    { :column_count => column_count }
  end

  def self.error_class
    JdbcConnection::DatabaseError
  end

  private

  def schema_name
    @options[:schema]
  end

  def object_exists?(type, name)
    found = false
    with_connection do |connection|
      connection.send(type, :schema_name => schema_name, :table_name => name).each do |result|
        if result[:name] == name
          found = true
          break
        end
      end
    end
    found
  end
end