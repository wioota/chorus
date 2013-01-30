class GpdbInstancePresenter < Presenter

  def to_hash
    {
      :name => model.name,
      :host => model.host,
      :port => model.port,
      :id => model.id,
      :shared => model.shared,
      :state => model.state,
      :provision_type => model.provision_type,
      :maintenance_db => model.maintenance_db,
      :description => model.description,
      :instance_provider => model.instance_provider,
      :version => model.version,
      :entity_type => 'gpdb_instance',
      :is_deleted => !model.deleted_at.nil?
    }.merge(owner_hash)
  end

  def complete_json?
    !rendering_activities?
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
