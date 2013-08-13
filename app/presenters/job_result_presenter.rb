class JobResultPresenter < Presenter
  def to_hash
    [:succeeded, :started_at, :finished_at].inject({}) do |hash, key|
      hash[key] = model.send(key)
      hash
    end
  end
end