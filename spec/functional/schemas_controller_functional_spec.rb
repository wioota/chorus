require 'spec_helper'

describe DataSources::SchemasController, :greenplum_integration => true, :type => :controller do
  let(:user) { data_source.owner }
  let(:data_source) { data_sources(:oracle) }
  before { log_in user }

  context 'with invalid credentials' do
    let(:account) { data_source.account_for_user(user) }
    before { account.invalid_credentials! }

    it 'responds with 403' do
      get :index, :data_source_id => data_source.to_param
      response.status.should == 403
    end
  end
end