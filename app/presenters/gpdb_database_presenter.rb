class GpdbDatabasePresenter < Presenter

  def to_hash
    {
      :id => model.id,
      :name => h(model.name),
      :instance => present(model.gpdb_instance)
    }
  end

  def complete_json?
    true
  end
end
