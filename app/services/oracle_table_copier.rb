class OracleTableCopier < GpTableCopier

  def load_table_definition
    # No way of testing ordinal position clause since we can't reproduce an out of order result from the following query
    rows = source_connection.fetch(describe_table, :table => source_table_name, :schema => source_schema_name)
    rows.map { |col_def| "\"#{col_def[:column_name]}\" #{convert_type(col_def[:data_type])}" }.join(", ")
  end

  def load_primary_key_clause
    columns = primary_key_columns
    columns.empty? ? '' : ", PRIMARY KEY(#{columns})"
  end

  def distribution_key_clause
    columns = primary_key_columns
    columns.empty? ? 'DISTRIBUTED RANDOMLY' : "DISTRIBUTED BY(#{columns})"
  end

  private

  def primary_key_columns
    return @primary_key_columns if @primary_key_columns
    query = source_connection[:all_cons_columns].select(:column_name).
        join(:all_constraints, :constraint_name => :constraint_name, :owner => :owner).
        where(:all_cons_columns__table_name => source_table_name, :all_cons_columns__owner => source_schema_name, :constraint_type => 'P').
        order(:all_cons_columns__position)

    @primary_key_columns = query.map { |column| "\"#{column[:column_name]}\"" }.join(', ')
  end

  def convert_type(oracle_type)
    oracle_type_without_specification = oracle_type.split("(").first
    TYPE_CONVERSIONS[oracle_type_without_specification]
  end

  def describe_table
    <<-SQL
      SELECT COLUMN_NAME as column_name, DATA_TYPE as data_type
      FROM ALL_TAB_COLUMNS
      WHERE TABLE_NAME = :table AND OWNER = :schema
      ORDER BY column_name
    SQL
  end

  TYPE_CONVERSIONS = {
      "BINARY_DOUBLE" => "float8",
      "BINARY_FLOAT" => "float8",
      "CHAR" => "character",
      "CLOB" => "text",
      "DATE" => "timestamp",
      "DECIMAL" => "float8",
      "INT" => "numeric",
      "LONG" => "text",
      "NCHAR" => "character",
      "NCLOB" => "text",
      "NUMBER" => "numeric",
      "NVARCHAR2" => "character varying",
      "ROWID" => "text",
      "TIMESTAMP" => "timestamp",
      "UROWID" => "text",
      "VARCHAR" => "character varying",
      "VARCHAR2" => "character varying",
      "TIMESTAMP with timezone" => "TIMESTAMP with timezone",
      "TIMESTAMP without timezone" => "TIMESTAMP without timezone"
  }
end