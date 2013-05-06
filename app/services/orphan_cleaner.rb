class OrphanCleaner
  def self.clean
    HdfsEntry.where("hdfs_data_source_id IN (SELECT id FROM hdfs_data_sources WHERE deleted_at IS NOT NULL)").find_each do |entry|
      entry.destroy
    end
  end
end