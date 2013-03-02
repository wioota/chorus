class GpdbDataSourcePresenter < DataSourcePresenter

  def to_hash
    super.merge({
      :is_deleted => !model.deleted_at.nil?,
      :instance_provider => model.instance_provider,
    })
  end

  def complete_json?
    !rendering_activities?
  end
end
