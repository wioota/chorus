class DashboardConfigPresenter < Presenter

  def to_hash
    { :modules => model.dashboard_items }
  end
end
