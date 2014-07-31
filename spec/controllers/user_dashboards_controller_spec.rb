require 'spec_helper'

describe UserDashboardsController do
  let(:user) { users(:the_collaborator) }

  describe 'show' do
    before do
      log_in user
      %w(Module2 Module1 Module3).each_with_index do |name, i|
        user.dashboard_items.create!(:name => name, :location => i)
      end
    end

    it 'presents the modules in order' do
      get :show, :user_id => user.id
      decoded_response.modules.should == %w(Module2 Module1 Module3)
    end

    it 'uses authorization' do
      log_in users(:no_collaborators)
      get :show, :user_id => user.id
      response.should be_forbidden
    end

    context 'when the user has no dashboard config' do
      before do
        user.dashboard_items.destroy_all
      end

      it 'uses the default' do
        get :show, :user_id => user.id
        decoded_response.modules.should == %w(Module1 Module2 Module3)
      end
    end
  end

  describe 'create' do
    before do
      log_in user
    end

    it 'updates the dashboard config for the user' do
      user.dashboard_items.create!(:name => 'Module1')

      post :create, :user_id => user.id, :modules => %w(Module3 Module2)

      user.reload.dashboard_items.order(:location).map(&:name).should == %w(Module3 Module2)
    end

    context 'when the new config is invalid' do
      let(:modules) { %w(InvalidModule) }

      before do
        user.dashboard_items.create!(:name => 'Module1')
        post :create, :user_id => user.id, :modules => modules
      end

      it 'does not change the existing' do
        user.reload.dashboard_items.map(&:name).should == %w(Module1)
      end

      it 'returns 422' do
        response.should be_unprocessable
      end
    end

    it 'uses authorization' do
      log_in users(:no_collaborators)
      post :create, :user_id => user.id
      response.should be_forbidden
    end
  end
end
