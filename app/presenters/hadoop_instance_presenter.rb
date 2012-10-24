class HadoopInstancePresenter < Presenter

  def to_hash
    {
        :name => h(model.name),
        :host => h(model.host),
        :port => model.port,
        :id => model.id,
        :owner => present(model.owner),
        :state => model.state,
        :description => model.description,
        :version => model.version,
        :username => model.username,
        :group_list => model.group_list,
        :entity_type => "hadoop_instance"
    }
  end

  def complete_json?
    true
  end
end
