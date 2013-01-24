class GpdbDatabasePresenter < Presenter

  def to_hash
    {
      :id => model.id,
      :name => model.name,
      :instance => present(model.gpdb_data_source)
    }
  end

  def complete_json?
    true
  end
end
