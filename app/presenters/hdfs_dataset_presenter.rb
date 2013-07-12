class HdfsDatasetPresenter < DatasetPresenter
  def to_hash
    super.merge({
        :file_mask => model.file_mask,
        :hdfs_data_source => model.hdfs_data_source,
        :object_type => subtype,
        :content => "Content Coming Soon"
    })
  end

  def subtype
    'HDFS'
  end
end