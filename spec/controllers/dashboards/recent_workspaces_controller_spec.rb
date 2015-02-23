require 'spec_helper'

describe Dashboards::RecentWorkspacesController do
  let(:user) { users(:owner) }

  before do
    log_in user
    user.dashboard_items.create!(:name => 'RecentWorkspaces', :location => 1)
    Workspace.last(6).each do |workspace|
      OpenWorkspaceEvent.create!(user: user, workspace: workspace)
    end
  end

  describe '#create' do
    context 'updating the option' do
      let(:params) do
        {
            :recent_workspaces => {
                :action => 'updateOption',
                :option_value => '6'
            }
        }
      end
      it 'updates the option parameter' do
        post :create, params
      end
    end

    context 'clearing the recent Workspaces list' do
      let(:params) do
        {
            :recent_workspaces => {
                :action => 'clearList',
            }
        }
      end
      it 'updates the option parameter' do
        user.dashboard_items.where(:name => 'RecentWorkspaces').update_all(:options => 6)
        recent_workspace = Dashboard::RecentWorkspaces.new({:user => user})
        recent_workspace.fetch!.result.length.should == 6
        post :create, params
        recent_workspace.fetch!.result.length.should == 0
      end
    end

  end
end
