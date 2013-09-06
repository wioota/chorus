require 'spec_helper'

describe Alpine::API do
  let(:alpine_base_uri) { 'http://localhost:8090' }
  let(:work_flow) { workfiles('multiple_data_source_workflow') }
  let(:config) { ChorusConfig.instance }
  let(:user) { users(:admin) }
  let(:mock_session_id) { 'fortytwo' }
  let(:database_ids) { work_flow.execution_locations.select { |source| source.is_a? GpdbDatabase }.map(&:id).map(&:to_s) }
  let(:hadoop_ids) { work_flow.execution_locations.select { |source| source.is_a? HdfsDataSource }.map(&:id).map(&:to_s) }

  subject { Alpine::API.new config: config, user: user }

  before do
    stub(ChorusConfig.instance).workflow_configured? { true }
    stub(config).workflow_url { alpine_base_uri }
  end

  describe '.delete_work_flow' do
    before { fake_a_session }
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
      fake_a_session
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
        stub(config).workflow_configured? { false }
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
    before { fake_a_session }

    let(:full_request_url)  { "#{alpine_base_uri}/alpinedatalabs/main/chorus.do?method=importWorkFlow&session_id=#{mock_session_id}&file_name=#{work_flow.file_name}&workfile_id=#{work_flow.id}" }
    let(:file)              { test_file('workflow.afm', "text/xml") }
    let(:file_contents)     { file.read }

    it "makes a POST request with the workflow contents and id" do
      FakeWeb.register_uri(:post, full_request_url, :status => 200, :body => file_contents, :content_type => "text/xml")
      subject.create_work_flow(work_flow, file_contents)
      FakeWeb.last_request.should be_a(Net::HTTP::Post)

      params = CGI::parse(URI(FakeWeb.last_request.path).query)
      params['session_id'][0].should == mock_session_id
      params['workfile_id'][0].should == work_flow.id.to_s
    end

    context 'when work_flow is disabled' do
      before do
        stub(config).workflow_configured? { false }
      end

      it 'does not make an http request' do
        any_instance_of(Net::HTTP) do |http|
          do_not_allow(http).request.with_any_args
        end

        subject.create_work_flow(work_flow, file_contents)
      end
    end
  end

  describe '.run_work_flow_task' do
    before { fake_a_session }
    let(:task) { job_tasks(:rwft) }

    it 'delegates to a new API instance' do
      any_instance_of(Alpine::API) do |api|
        mock(api).run_work_flow(task.payload, task: task)
      end

      Alpine::API.run_work_flow_task(task)
    end
  end

  describe '#run_work_flow' do
    before do
      VCR.configure { |c| c.ignore_localhost = true }
      any_instance_of(Session) do |session|
        stub(session).session_id { mock_session_id }
      end
    end

    describe 'when there are existing unexpired sessions' do
      before do
        session = Session.new
        session.user = user
        session.save!
        register_run_success_post
      end

      it 'does not create a session' do
        expect {
          subject.run_work_flow(work_flow)
        }.not_to change(Session, :count)
      end
    end

    describe 'when there are existing sessions that are only expired' do
      before do
        session = Session.new
        session.user = user
        session.save!
        session.update_attribute(:updated_at, 1.year.ago)
        register_run_success_post
      end

      it 'creates a new session' do
        expect {
          subject.run_work_flow(work_flow)
        }.to change(Session, :count).by(1)
        Session.last.user_id.should == user.id
      end
    end

    it 'makes a POST request with the necessary params' do
      register_run_success_post
      subject.run_work_flow(work_flow)
      FakeWeb.last_request.should be_a(Net::HTTP::Post)
      params = CGI::parse(URI(FakeWeb.last_request.path).query)
      params['session_id'][0].should == mock_session_id.to_s
      params['workfile_id'][0].should == work_flow.id.to_s
      params['database_id[]'].should =~ database_ids
      params['hdfs_data_source_id[]'].should =~ hadoop_ids
    end

    it 'raises exception if the request is not a 200' do
      FakeWeb.register_uri(:post, %r|method=runWorkFlow|, :status => 500, :body => 'oh no')
      expect {
        subject.run_work_flow(work_flow)
      }.to raise_error(StandardError, 'oh no')
    end

    it "returns the process_id from alpine on success" do
      register_run_success_post('marzipan')
      subject.run_work_flow(work_flow).should == "marzipan"
    end

    context "when called with a task" do
      let(:task) { job_tasks(:rwft) }
      let(:work_flow) { task.payload }

      it 'makes a POST request with job_task_id' do
        register_run_success_post
        subject.run_work_flow(task.payload, task: task)
        FakeWeb.last_request.should be_a(Net::HTTP::Post)
        params = CGI::parse(URI(FakeWeb.last_request.path).query)
        params['session_id'][0].should == mock_session_id.to_s
        params['workfile_id'][0].should == task.payload.id.to_s
        params['job_task_id'][0].should == task.id.to_s
        params['database_id[]'].should =~ database_ids
        params['hdfs_data_source_id[]'].should =~ hadoop_ids
      end
    end
  end

  describe '.stop_work_flow_task' do
    before { fake_a_session }
    let(:task) { job_tasks(:rwft) }

    it 'delegates to a new API instance' do
      any_instance_of(Alpine::API) do |api|
        mock(api).stop_work_flow(task.killable_id)
      end

      Alpine::API.stop_work_flow_task(task)
    end
  end

  describe '#stop_work_flow' do
    before do
      VCR.configure { |c| c.ignore_localhost = true }
      any_instance_of(Session) do |session|
        stub(session).session_id { mock_session_id }
      end
    end


    describe 'when there are existing unexpired sessions' do
      before do
        session = Session.new
        session.user = user
        session.save!
        FakeWeb.register_uri(:post, %r|method=stopWorkFlow|, :status => 200)
      end

      it 'does not create a session' do
        expect {
          subject.stop_work_flow(work_flow)
        }.not_to change(Session, :count)
      end
    end

    describe 'when there are existing sessions that are only expired' do
      before do
        session = Session.new
        session.user = user
        session.save!
        session.update_attribute(:updated_at, 1.year.ago)
        FakeWeb.register_uri(:post, %r|method=stopWorkFlow|, :status => 200)
      end

      it 'creates a new session' do
        expect {
          subject.stop_work_flow(work_flow)
        }.to change(Session, :count).by(1)
        Session.last.user_id.should == user.id
      end
    end

    it 'makes a POST request with the necessary params' do
      FakeWeb.register_uri(:post, %r|method=stopWorkFlow|, :status => 200)

      subject.stop_work_flow('killbill')

      FakeWeb.last_request.should be_a(Net::HTTP::Post)
      params = CGI::parse(URI(FakeWeb.last_request.path).query)
      params['session_id'][0].should == mock_session_id.to_s
      params['process_id'][0].should == 'killbill'
    end
  end
end

def fake_a_session
  user.password = 'anything'
  user.save
  stub.proxy(config).[](anything)

  Session.create!(:username => user.username, :password => 'anything')

  any_instance_of(Session) do |session|
    stub(session).session_id { mock_session_id }
  end
end

def register_run_success_post(process_id = "beverlyhills90210")
  FakeWeb.register_uri(:post, %r|method=runWorkFlow|, :status => 200, :body => %|{"process_id": "#{process_id}"}|)
end
