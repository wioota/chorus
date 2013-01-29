class OracleDataSourcePresenter < Presenter
  def to_hash
    {
        :id => model.id,
        :name => model.name,
        :host => model.host,
        :port => model.port,
        :db_name => model.db_name,
        :description => model.description,
        :version => model.version,
        :entity_type => model.entity_type_name
    }
  end
end