module OracleDbTypeConversions
  MISCELLANEOUS_TYPES = []

  CATEGORY_MAP = {
      "BFILE" => "OTHER",
      "BINARY_DOUBLE" => "REAL_NUMBER",
      "BINARY_FLOAT" => "REAL_NUMBER",
      "BLOB" => "OTHER",
      "CHAR" => "STRING",
      "CLOB" => "LONG_STRING",
      "DATE" => "DATETIME",
      "DECIMAL" => "REAL_NUMBER",
      "INT" => "WHOLE_NUMBER",
      "LONG" => "LONG_STRING",
      "LONG RAW" => "OTHER",
      "MLSLABEL" => "OTHER",
      "NCHAR" => "STRING",
      "NCLOB" => "LONG_STRING",
      "NUMBER" => "WHOLE_NUMBER",
      "NVARCHAR2" => "STRING",
      "RAW" => "OTHER",
      "ROWID" => "LONG_STRING",
      "TIMESTAMP" => "DATETIME",
      "UROWID" => "LONG_STRING",
      "VARCHAR" => "STRING",
      "VARCHAR2" => "STRING",
      "XMLTYPE" => "OTHER",
      "TIMESTAMP WITH TIME ZONE" => "DATETIME",
      "TIMESTAMP WITHOUT TIME ZONE" => "DATETIME",
      "TIMESTAMP(6)" => "DATETIME"
  }

  GREENPLUM_TYPE_MAP = {
      "BINARY_DOUBLE" => "float8",
      "BINARY_FLOAT" => "float8",
      "CHAR" => "character",
      "CLOB" => "text",
      "DATE" => "timestamp",
      "LONG" => "text",
      "DECIMAL" => "float8",
      "INT" => "numeric",
      "NCHAR" => "character",
      "NCLOB" => "text",
      "NUMBER" => "numeric",
      "NVARCHAR2" => "character varying",
      "ROWID" => "text",
      "TIMESTAMP" => "timestamp",
      "UROWID" => "text",
      "VARCHAR" => "character varying",
      "VARCHAR2" => "character varying",
      "TIMESTAMP WITH TIME ZONE" => "TIMESTAMP with timezone",
      "TIMESTAMP WITHOUT TIME ZONE" => "TIMESTAMP without timezone"
  }

  def to_category(data_type)
    OracleDbTypeConversions.to_category(data_type)
  end

  def convert_column_type(oracle_type)
    OracleDbTypeConversions.to_category(data_type)
  end

  def self.convert_column_type(oracle_type)
    oracle_type_without_specification = oracle_type.split("(").first
    GREENPLUM_TYPE_MAP[oracle_type_without_specification]
  end

  def self.to_category(data_type)
    CATEGORY_MAP[data_type.upcase]
  end
end