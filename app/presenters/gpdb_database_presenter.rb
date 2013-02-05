class GpdbDatabasePresenter < Presenter

  def to_hash
    {
      :id => model.id,
      :name => model.name,
      :instance => present(model.data_source),
      :entity_type => model.entity_type_name
    }
  end

  def complete_json?
    true
  end
end
