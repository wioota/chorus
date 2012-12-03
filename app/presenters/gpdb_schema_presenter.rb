class GpdbSchemaPresenter < Presenter

  def to_hash
    {
        :id => model.id,
        :name => model.name,
        :database => present(model.database),
        :dataset_count => model.active_tables_and_views.size,
        :has_credentials => model.accessible_to(current_user),
        :refreshed_at => model.refreshed_at
    }
  end

  def complete_json?
    true
  end
end
