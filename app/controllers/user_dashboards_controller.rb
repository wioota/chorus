class UserDashboardsController < ApplicationController

  def show
    authorize! :update, user
    modules = user.dashboard_items.order(:location).map &:name

    if modules.empty?
      modules = DashboardItem::DEFAULT_MODULES
    end

    render :json => { :response => { :modules => modules } }
  end

  private

  def user
    @user ||= User.find params[:user_id]
  end
end
