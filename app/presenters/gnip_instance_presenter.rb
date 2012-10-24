class GnipInstancePresenter < Presenter

  def to_hash
    {
        :name => h(model.name),
        :stream_url => h(model.stream_url),
        :id => model.id,
        :owner => model.owner,
        :description => model.description,
        :username => model.username,
        :state => "online",
        :entity_type => "gnip_instance"
    }
  end

  def complete_json?
    true
  end
end
