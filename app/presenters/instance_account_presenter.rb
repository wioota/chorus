class InstanceAccountPresenter < Presenter

  def to_hash
    {
      :id => model.id,
      :db_username => model.db_username,
      :owner_id => model.owner_id,
      :instance_id => model.instance_id,
      :owner => present(model.owner),
      :entity_type => model.entity_type_name
    }
  end

  def complete_json?
    true
  end
end