class GpdbSchemaPresenter < Presenter
    def to_hash
    {
        :id => model.id,
        :name => model.name,
        :database => present(model.database),
        :dataset_count => model.active_tables_and_views_count,
        :has_credentials => model.accessible_to(current_user),
        :refreshed_at => model.refreshed_at,
        :entity_type => model.entity_type_name
    }
  end

  def complete_json?
    true
  end
end
