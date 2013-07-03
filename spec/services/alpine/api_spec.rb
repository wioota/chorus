require 'spec_helper'

describe Alpine::API do
  let(:alpine_base_uri) { 'http://localhost:8090' }
  let(:work_flow) { workfiles('alpine_flow') }
  let(:config) { ChorusConfig.instance }
  let(:user) { users(:admin) }
  let(:mock_session_id) { 'fortytwo' }
  subject { Alpine::API.new config: config, user: user }

  before do
    fake_a_session
  end

  describe '.delete_work_flow' do
    let(:work_flow) { workfiles('alpine_flow') }

    it 'delegates to a new API instance' do
      any_instance_of(Alpine::API) do |api|
        mock(api).delete_work_flow(work_flow)
      end

      Alpine::API.delete_work_flow(work_flow)
    end
  end

  describe '#delete_work_flow' do
    let(:full_request_url) { "#{alpine_base_uri}/alpinedatalabs/main/chorus.do?method=deleteWorkFlow&session_id=#{mock_session_id}&workfile_id=#{work_flow.id}" }

    before do
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

  describe '#create_work_flow' do
    let(:full_request_url)  { "#{alpine_base_uri}/alpinedatalabs/main/chorus.do?method=importWorkFlow&session_id=#{mock_session_id}&file_name=#{work_flow.file_name}&workfile_id=#{work_flow.id}" }
    let(:file)              { test_file('workflow.afm', "text/xml") }
    let(:file_contents)     { file.read }

    it "makes a POST request with the workflow contents and id" do
      FakeWeb.register_uri(:post, full_request_url, :status => 200, :body => file_contents, :content_type => "text/xml")
      subject.create_work_flow(work_flow, file_contents)
      FakeWeb.last_request.should be_a(Net::HTTP::Post)
    end

    context 'when work_flow is disabled' do
      before do
        stub(config).work_flow_configured? { false }
      end

      it 'does not make an http request' do
        any_instance_of(Net::HTTP) do |http|
          do_not_allow(http).request.with_any_args
        end

        subject.create_work_flow(work_flow, file_contents)
      end
    end
  end
end

def fake_a_session
  user.password = 'anything'
  user.save
  stub.proxy(config).[](anything)
  stub(config).work_flow_configured? { true }
  stub(config).[]('work_flow.url') { alpine_base_uri }

  Session.create!(:username => user.username, :password => 'anything')

  any_instance_of(Session) do |session|
    stub(session).session_id { mock_session_id }
  end
end