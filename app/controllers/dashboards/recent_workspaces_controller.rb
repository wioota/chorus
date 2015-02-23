module Dashboards
  class RecentWorkspacesController < ApplicationController
    wrap_parameters :recent_workspaces

    def create
      authorize! :update, current_user
      if (params[:recent_workspaces][:action] == 'updateOption')
        option_value = params[:recent_workspaces][:option_value]
        config = DashboardConfig.new(current_user)
        config.set_options('RecentWorkspaces', option_value)
      elsif (params[:recent_workspaces][:action] == 'clearList')
        OpenWorkspaceEvent.where(:user_id => current_user).destroy_all
      end
      render :json => {}
    end
  end

end
