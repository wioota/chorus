class GpdbDataSourcePresenter < DataSourcePresenter

  def to_hash
    super.merge(specific_data)
  end

  private

  def specific_data
    return {} if succinct?
    {
        :is_deleted => !model.deleted_at.nil?,
        :instance_provider => model.instance_provider,
    }
  end
end
