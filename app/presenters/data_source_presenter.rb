class DataSourcePresenter < Presenter
  def to_hash
    hash = {
        :id => model.id,
        :name => model.name,
        :entity_type => model.entity_type_name
    }
    unless succinct?
      hash.merge!({
          :host => model.host,
          :port => model.port,
          :shared => model.shared,
          :online => model.state == "online",
          :db_name => model.db_name,
          :description => model.description,
          :version => model.version
      }.merge(owner_hash).
      merge(tags_hash))
    end
    hash
  end

  def complete_json?
    !rendering_activities? && !succinct?
  end

  private

  def tags_hash
    rendering_activities? ? {} : {:tags => present(model.tags)}
  end

  def owner_hash
    if rendering_activities?
      {}
    else
      {:owner => present(model.owner)}
    end
  end
end