class JobResultPresenter < Presenter
  def to_hash
    hash =[:succeeded, :started_at, :finished_at, :id].inject({}) do |hash, key|
      hash[key] = model.send(key)
      hash
    end

    hash[:job_task_results] = model.job_task_results.map { |result| present(result) }
    hash
  end
end