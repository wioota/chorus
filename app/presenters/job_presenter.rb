class JobPresenter < Presenter

  def to_hash
    job = {
      :id => model.id,
      :workspace => present(model.workspace, options.merge(:succinct => options[:succinct] || options[:list_view])),
      :name => model.name,
      :next_run => model.next_run,
      :last_run => model.last_run,
      :interval_unit => model.interval_unit,
      :interval_value => model.interval_value,
      :state => model.enabled ? 'scheduled' : 'disabled'
    }

    job[:tasks] = model.job_tasks unless options[:list_view]

    job
  end
end
