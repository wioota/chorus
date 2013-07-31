class JobTaskPresenter < Presenter

  def to_hash
    {
      :id => model.id,
      :job => present(model.job, list_view: true),
      :workspace => present(model.job.workspace, list_view: true),
      :action => model.action,
      :index => model.index,
      :name => model.name
    }
  end
end