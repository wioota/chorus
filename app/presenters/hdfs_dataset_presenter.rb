class HdfsDatasetPresenter < DatasetPresenter
  def succinct_hash
    super.merge({
        :file_mask => model.file_mask,
        :hdfs_data_source => model.hdfs_data_source,
        :object_type => subtype
    })
  end

  def complete_hash
    super.merge({
      :content => model.contents
    })
  end

  def subtype
    'HDFS'
  end
end