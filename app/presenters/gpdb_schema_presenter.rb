class GpdbSchemaPresenter < Presenter
  def to_hash
    hash = {
        :id => model.id,
        :name => model.name,
        :database => present(model.database, options),
        :dataset_count => model.active_tables_and_views_count,
        :refreshed_at => model.refreshed_at,
        :entity_type => model.entity_type_name
    }
    unless succinct?
      hash.merge!({
        :has_credentials => model.accessible_to(current_user)
      })
    end
    hash
  end

  def complete_json?
    true
  end
end
