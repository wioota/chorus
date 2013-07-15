class HdfsDatasetPresenter < DatasetPresenter
  def succinct_hash
    super.merge({
        :file_mask => model.file_mask,
        :hdfs_data_source => model.hdfs_data_source,
        :object_type => 'MASK'
    })
  end

  def complete_hash
    super.merge({
      :content => model.contents
    })
  end


  private

  def subtype
    'HDFS'
  end
end