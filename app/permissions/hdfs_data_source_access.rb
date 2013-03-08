class HdfsDataSourceAccess < AdminFullAccess
  def edit?(hdfs_data_source)
    hdfs_data_source.owner == current_user
  end

  def show?(hdfs_data_source)
    true
  end
end
