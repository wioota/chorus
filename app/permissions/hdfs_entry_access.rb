class HdfsEntryAccess < AdminFullAccess
  def show?(hdfs_entry)
    HadoopInstanceAccess.new(context).can? :show, hdfs_entry.hadoop_instance
  end
end