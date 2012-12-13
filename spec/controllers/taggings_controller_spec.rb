require 'spec_helper'

describe TaggingsController do
  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe 'create' do
    let(:workfile) { workfiles(:'sql.sql') }
    let(:params) { { :entity_id => workfile.id, :entity_type => 'workfile', :tag_names => ['alpha', 'beta'] } }

    it 'sets the tags to the workfile' do
      post :create, params
      response.code.should == '201'
      workfile.reload.tags.map(&:name).should =~ ['alpha', 'beta']
    end

    context 'when the user does not have permission to tag the workfile' do
      let(:user) { users(:no_collaborators) }

      it 'returns unauthorized' do
        post :create, params
        response.code.should == '403'
      end
    end
  end
end