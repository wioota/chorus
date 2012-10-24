class InstanceAccountPresenter < Presenter

  def to_hash
    {
      :id => model.id,
      :db_username => h(model.db_username),
      :owner_id => model.owner_id,
      :instance_id => model.gpdb_instance_id,
      :owner => present(model.owner)
    }
  end

  def complete_json?
    true
  end
end