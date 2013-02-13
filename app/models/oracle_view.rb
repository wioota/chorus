class OracleView < OracleDataset
  def verify_in_source(user)
    schema.connect_as(user).view_exists?(name)
  end

  def all_rows_sql(limit = nil)
    query = "SELECT * from \"#{schema.name}\".\"#{name}\""
    query << " WHERE rownum <= #{limit}" if limit
    query
  end
end