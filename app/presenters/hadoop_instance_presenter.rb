class HadoopInstancePresenter < Presenter

  def to_hash
    {
        :name => model.name,
        :host => model.host,
        :port => model.port,
        :id => model.id,
        :state => model.state,
        :description => model.description,
        :version => model.version,
        :username => model.username,
        :group_list => model.group_list,
        :entity_type => "hadoop_instance"
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
