class JobPresenter < Presenter

  def to_hash
    job_hash = {
      :id => model.id,
      :workspace => present(model.workspace, options.merge(:succinct => options[:succinct] || options[:list_view])),
      :name => model.name,
      :next_run => next_run,
      :end_run => model.end_run,
      :time_zone => model.time_zone,
      :last_run => model.last_run,
      :interval_unit => model.interval_unit,
      :interval_value => model.interval_value,
      :status => model.status,
      :enabled => model.enabled
    }

    job_hash[:tasks] = model.job_tasks.map { |task| present(task) } unless options[:list_view]

    job_hash
  end

  private

  def next_run
    if model.next_run
      model.next_run.in_time_zone(ActiveSupport::TimeZone[model.time_zone])
    end
  end

end
