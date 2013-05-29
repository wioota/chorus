require 'spec_helper'

describe Alpine::WorkspaceDatasetsController do
  let(:user) { users(:the_collaborator) }

  before do
    log_in user
  end

  describe '#index' do
    let(:workspace) { workspaces(:public) }
    let(:gpdb_view) { datasets(:view) }
    let(:gpdb_table) { datasets(:table) }
    let(:the_datasets) { fake_relation [gpdb_table, gpdb_view] }

    before do
      stub(workspace).datasets { the_datasets }
      stub(request).remote_ip { '127.0.0.1' }
      stub(request).remote_addr { '::1' }
    end

    context 'when alpine is enabled' do
      before do
        stub(ChorusConfig.instance).work_flow_configured? { true }
      end

      context 'for local requests' do
        before do
          mock(Workspace).
              workspaces_for(user).mock!.
              find(workspace.to_param) { workspace }
        end

        [
            '127.0.0.1',
            '::1',
            '0:0:0:0:0:0:0:1%0',
            '::ffff:127.0.0.1'
        ].each do |ip|
          it "presents the workspace datasets succinctly for #{ip}" do
            stub(request).remote_ip { ip }
            stub(request).remote_addr { ip }
            mock_present do |collection, _, options|
              collection.to_a.to_a.should =~ the_datasets.to_a
              options.should == {:workspace => workspace, :succinct => true}
            end

            get :index, :workspace_id => workspace.to_param
            response.should be_success
          end
        end
      end

      context 'for non-local requests' do
        let(:ip) { '64.55.103.11' }

        it 'returns not found' do
          stub(request).remote_ip { ip }
          stub(request).remote_addr { ip }
          get :index, :workspace_id => workspace.to_param
          response.should be_not_found
        end
      end
    end

    context 'when alpine is not enabled' do
      before do
        stub(ChorusConfig.instance).work_flow_configured? { false }
      end

      it 'returns not found' do
        get :index, :workspace_id => workspace.to_param
        response.should be_not_found
      end
    end
  end
end