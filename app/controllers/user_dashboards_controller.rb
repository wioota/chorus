class UserDashboardsController < ApplicationController
  wrap_parameters :dashboard_config
  before_filter :load_user
  before_filter :require_referenced_user

  def show
    present DashboardConfig.new(@user)
  end

  def create
    modules = params[:dashboard_config][:modules]
    config = DashboardConfig.new(@user)
    config.update(modules)

    present config
  end

  private

  def load_user
    @user ||= User.find params[:user_id]
  end
end
