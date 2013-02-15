module OracleDbTypesToChorus
  MISCELLANEOUS_TYPES = []

  MAP = {
      "BFILE" => "OTHER",
      "BINARY_DOUBLE" => "REAL_NUMBER",
      "BINARY_FLOAT" => "REAL_NUMBER",
      "BLOB" => "OTHER",
      "CHAR" => "STRING",
      "CLOB" => "LONG_STRING",
      "DATE" => "DATE",
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
      "TIMESTAMP" => "DATE",
      "UROWID" => "LONG_STRING",
      "VARCHAR" => "STRING",
      "VARCHAR2" => "STRING",
      "XMLTYPE" => "OTHER",
      "TIMESTAMP WITH TIME ZONE" => "DATETIME",
      "TIMESTAMP WITHOUT TIME ZONE" => "DATETIME"
  }

  def to_category(data_type)
    MAP[data_type.upcase]
  end
end