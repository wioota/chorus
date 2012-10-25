class GpdbInstancePresenter < Presenter

  def to_hash
    {
      :name => h(model.name),
      :host => h(model.host),
      :port => model.port,
      :id => model.id,
      :owner => present(model.owner),
      :shared => model.shared,
      :state => model.state,
      :provision_type => model.provision_type,
      :maintenance_db => model.maintenance_db,
      :description => model.description,
      :instance_provider => model.instance_provider,
      :version => model.version,
      :entity_type => 'gpdb_instance'
    }
  end

  def complete_json?
    true
  end
end
