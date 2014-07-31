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
      log_in users(:no_picture)
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
end
