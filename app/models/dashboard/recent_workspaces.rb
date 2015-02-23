module Dashboard
  class RecentWorkspaces < DataModule

    attr_reader :user

    def assign_params(params)
      @user = params[:user]
    end

    private

    def fetch_results
      limitValue = user.dashboard_items.where(:name => 'RecentWorkspaces').select('options').map(&:options).first
      if limitValue == ''
        limitValue = 5
    end

        OpenWorkspaceEvent.
          select('max(created_at) as created_at, workspace_id').
          where(:user_id => user.id).
          group(:workspace_id).
          order('created_at DESC').
          includes(:workspace).
          limit(limitValue)
        end
  
  end
end
