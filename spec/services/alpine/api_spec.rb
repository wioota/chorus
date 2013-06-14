require 'spec_helper'

describe Alpine::API do
  describe '.delete_work_flow' do
    let(:work_flow)  { workfiles('alpine.afm') }
    let(:mock_session_id) { 'fortytwo' }
    let(:user) { users(:admin) }
    let(:full_request_url) { "http://localhost:8090/alpinedatalabs/main/chorus.do?method=deleteWorkFlow&session_id=#{mock_session_id}&workfile_id=#{work_flow.id}" }

    before do
      user.password = 'anything'
      user.save
      stub.proxy(ChorusConfig.instance).[](anything)
      stub(ChorusConfig.instance).work_flow_configured? { true }
      stub(ChorusConfig.instance).[]('work_flow.url') { 'http://localhost:8090' }

      Session.create!(:username => user.username, :password => 'anything')
      stub(User).current_user { user }
      any_instance_of(Session) do |sesh|
        stub(sesh).session_id { mock_session_id }
      end
      VCR.configure do |c|
        c.ignore_localhost = true
      end
    end

    it 'makes a DELETE request with the necessary params' do
      FakeWeb.register_uri(:delete, full_request_url, :status => 200)
      Alpine::API.delete_work_flow(work_flow)
      FakeWeb.last_request.should be_a(Net::HTTP::Delete)
    end

    context 'when Alpine is unavailable' do
      it 'handles SocketError' do
        FakeWeb.register_uri(:delete, full_request_url, :exception => SocketError)
        expect {
          Alpine::API.delete_work_flow(work_flow)
        }.to_not raise_error
      end

      it 'handles Errno::ECONNREFUSED' do
        FakeWeb.register_uri(:delete, full_request_url, :exception => Errno::ECONNREFUSED)
        expect {
          Alpine::API.delete_work_flow(work_flow)
        }.to_not raise_error
      end
    end

    context 'when work_flow is disabled' do
      before do
        stub(ChorusConfig.instance).work_flow_configured? { false }
      end

      it 'does not make an http request' do
        any_instance_of(Net::HTTP) do |http|
          do_not_allow(http).request.with_any_args
        end

        Alpine::API.delete_work_flow(work_flow)
      end
    end
  end
end