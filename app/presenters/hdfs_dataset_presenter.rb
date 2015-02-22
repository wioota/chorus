class HdfsDatasetPresenter < DatasetPresenter
  def succinct_hash
    super.merge({
        :file_mask => model.file_mask,
        :hdfs_data_source => Presenter.present(model.hdfs_data_source, @view_context, options),
        :object_type => 'MASK'
    })
  end

  def complete_hash
    options[:workspace] = model.workspace
    hash = super
    hash.merge!({:content => model.contents}) if with_content
    hash
  end

  private

  def subtype
    'HDFS'
  end

  def with_content
    @options[:with_content]
  end
end