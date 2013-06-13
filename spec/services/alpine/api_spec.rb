require 'spec_helper'

describe Alpine::API do
  describe '.delete_work_flow' do
    let(:work_flow)  { workfiles('alpine.afm') }
    let(:mock_session_id) { 'fortytwo' }
    let(:user) { users(:admin) }

    before do
      user.password = 'anything'
      user.save

      Session.create!(:username => user.username, :password => 'anything')
      mock(User).current_user { user }
      any_instance_of(Session) do |sesh|
        mock(sesh).session_id { mock_session_id }
      end
    end

    it 'passes the necessary parameters in a DELETE request' do
      any_instance_of(Net::HTTP) do |http|
        stub(http).request
      end

      mock(Net::HTTP::Delete).new(anything) do |string|
        uri = URI("http://localhost#{string}")
        uri.path.should == '/alpinedatalabs/main/chorus.do'

        uri.query.should == {
          method: 'deleteWorkFlow',
          session_id: mock_session_id,
          workfile_id: work_flow.id
        }.to_query
      end

      Alpine::API.delete_work_flow(work_flow)
    end

    it 'makes a request' do
      any_instance_of(Net::HTTP) do |http|
        mock(http).request be_a(Net::HTTP::Delete)
      end
      Alpine::API.delete_work_flow(work_flow)
    end

    context "when Alpine is unavailable" do
      before do
        any_instance_of(Net::HTTP) do |http|
          mock(http).request(anything) { raise SocketError.new('initialize: name or service not known') }
        end
      end

      it "does not explode" do
        expect {
          Alpine::API.delete_work_flow(work_flow)
        }.to_not raise_error
      end
    end
  end
end