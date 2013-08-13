class JobTaskPresenter < Presenter

  def to_hash
    {
      :id => model.id,
      :job => present(model.job, succinct: true),
      :action => model.action,
      :index => model.index,
      :name => model.build_task_name,
      :is_deleted => model.deleted?
    }
  end
end