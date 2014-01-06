class JdbcConnection < DataSourceConnection
  class DatabaseError < Error; end

  def db_url
    @data_source.url
  end

  def db_options
    super.merge :identifier_output_method => nil
  end

  def version
    with_connection { |connection| connection.version }.slice(0,255)
  end

  def schemas
    with_connection { |connection| connection.schemas }
  end

  def schema_exists?(name)
    schemas.include? name
  end

  def table_exists?(name)
    object_exists? :tables, name
  end

  def view_exists?(name)
    object_exists? :views, name
  end

  def datasets(options={})
    with_connection do |connection|
      res = connection.datasets(:schema => schema_name)
      res.take(options[:limit] || res.size)
    end
  end

  def datasets_count(options={})
    datasets(options).size
  end

  def metadata_for_dataset(dataset_name)
    column_count = with_connection { |connection| connection.schema(dataset_name, {:schema => schema_name}).size }
    {:column_count => column_count}
  end

  def column_info(dataset_name, setup_sql)
    with_connection do |connection|
      connection.schema(dataset_name, {:schema => schema_name}).map do |col|
        { :attname => col[0].to_s, :format_type => col[1][:type].to_s }
      end
    end
  end

  def create_sql_result(warnings, result_set)
    JdbcSqlResult.new(:warnings => warnings, :result_set => result_set)
  end

  def self.error_class
    JdbcConnection::DatabaseError
  end

  private

  def schema_name
    @options[:schema]
  end

  def object_exists?(type, name)
    return false unless name
    with_connection do |connection|
      res = connection.send(type, :schema => schema_name, :table_name => name)
      res.include? name.to_sym
    end
  end
end