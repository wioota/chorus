class OracleTableCopier < TableCopier
  private

  def distribution_key_columns
    primary_key_columns
  end

  def convert_column_type(oracle_type)
    oracle_type_without_specification = oracle_type.split("(").first
    TYPE_CONVERSIONS[oracle_type_without_specification]
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