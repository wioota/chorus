class OracleDataSourcePresenter < Presenter
  def to_hash
    {
        :id => model.id,
        :name => model.name,
        :host => model.host,
        :port => model.port,
        :db_name => model.db_name,
        :description => model.description,
        :online => model.state == "online",
        :version => model.version,
        :shared => model.shared,
        :entity_type => model.entity_type_name
    }.merge(owner_hash)
  end

  private

  def owner_hash
    if rendering_activities?
      {}
    else
      {:owner => present(model.owner)}
    end
  end
end