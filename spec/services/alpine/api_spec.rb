require 'spec_helper'

describe Alpine::API do
  describe '.delete_work_flow' do
    let(:work_flow) { workfiles('alpine.afm') }

    it 'delegates to a new API instance' do
      any_instance_of(Alpine::API) do |api|
        mock(api).delete_work_flow(work_flow)
      end

      Alpine::API.delete_work_flow(work_flow)
    end
  end

  describe '#delete_work_flow' do
    let(:work_flow) { workfiles('alpine.afm') }
    let(:mock_session_id) { 'fortytwo' }
    let(:config) { ChorusConfig.instance }
    let(:user) { users(:admin) }
    let(:work_flow_url) { 'http://localhost:8090' }
    let(:full_request_url) { "#{work_flow_url}/alpinedatalabs/main/chorus.do?method=deleteWorkFlow&session_id=#{mock_session_id}&workfile_id=#{work_flow.id}" }
    subject { Alpine::API.new config: config, user: user }

    before do
      user.password = 'anything'
      user.save
      stub.proxy(config).[](anything)
      stub(config).work_flow_configured? { true }
      stub(config).[]('work_flow.url') { work_flow_url }

      Session.create!(:username => user.username, :password => 'anything')

      any_instance_of(Session) do |session|
        stub(session).session_id { mock_session_id }
      end

      VCR.configure do |c|
        c.ignore_localhost = true
      end
    end

    it 'makes a DELETE request with the necessary params' do
      FakeWeb.register_uri(:delete, full_request_url, :status => 200)
      subject.delete_work_flow(work_flow)
      FakeWeb.last_request.should be_a(Net::HTTP::Delete)
    end

    context 'when Alpine is unavailable' do
      it 'handles SocketError' do
        FakeWeb.register_uri(:delete, full_request_url, :exception => SocketError)
        expect { subject.delete_work_flow(work_flow) }.to_not raise_error
      end

      it 'handles Errno::ECONNREFUSED' do
        FakeWeb.register_uri(:delete, full_request_url, :exception => Errno::ECONNREFUSED)
        expect { subject.delete_work_flow(work_flow) }.to_not raise_error
      end

      it 'handles TimeoutError' do
        FakeWeb.register_uri(:delete, full_request_url, :exception => TimeoutError)
        expect { subject.delete_work_flow(work_flow) }.to_not raise_error
      end
    end

    context 'when work_flow is disabled' do
      before do
        stub(config).work_flow_configured? { false }
      end

      it 'does not make an http request' do
        any_instance_of(Net::HTTP) do |http|
          do_not_allow(http).request.with_any_args
        end

        subject.delete_work_flow(work_flow)
      end
    end
  end
end