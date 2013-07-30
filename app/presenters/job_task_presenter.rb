class JobTaskPresenter < Presenter

  def to_hash
    {
      :job => present(model.job),
      :action => model.action,
      :index => model.index,
      :name => model.name
    }
  end
end