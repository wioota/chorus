require 'spec_helper'

describe JobTasksController do
  let(:workspace) { workspaces(:public) }
  let(:job) { jobs(:default) }
  let(:user) { users(:owner) }
  let(:dataset) { datasets(:table) }

  before do
    log_in user
  end

  describe '#create' do
    let(:destination_dataset) { datasets(:other_table) }
    let(:params) do
      {
        :workspace_id => workspace.id,
        :job_id => job.id,
        :job_task => planned_job_task
      }
    end

    context 'import tasks' do
      let(:planned_job_task) do
        {
          :action => 'import_source_data',
          :source_id => dataset.id,
          :destination_id => destination_dataset.id,
          :row_limit => '500',
          :truncate => false,
          :index => 150
        }
      end

      context 'with an existing destination table' do
        it 'creates a job task' do
          expect do
            post :create, params
          end.to change(ImportSourceDataTask, :count).by(1)
        end
      end

      context 'with a new destination table' do
        let(:planned_job_task) do
          {
            :action => 'import_source_data',
            :source_id => dataset.id,
            :destination_name => 'into_this_one',
            :row_limit => '500',
            :truncate => false,
            :index => '45'
          }
        end

        it 'creates a job task' do
          expect do
            post :create, params
          end.to change(ImportSourceDataTask, :count).by(1)
        end
      end

      it "uses authorization" do
        mock(subject).authorize! :can_edit_sub_objects, workspace
        post :create, params
      end

      it "returns 201" do
        post :create, params
        response.code.should == "201"
      end
    end
  end

  describe '#update' do
    let(:task) { job_tasks(:isdt) }
    let(:params) do
      {
        :id => task.id,
        :workspace_id => workspace.id,
        :job_id => job.id,
        :job_task => planned_job_task
      }
    end

    context 'import_source_data' do
      let(:planned_job_task) do
        {
          :action => 'import_source_data',
          :source_id => dataset.id,
          :destination_id => nil,
          :destination_name => 'sandwich_table',
          :row_limit => '500',
          :truncate => false,
          :index => 150
        }
      end

      it 'changes a job task' do
        expect do
          put :update, params
        end.to change { task.payload.reload.destination_name }.to('sandwich_table')
        decoded_response[:destination_name].should == 'sandwich_table'
        response.code.should == "200"
      end

      it "uses authorization" do
        mock(subject).authorize! :can_edit_sub_objects, workspace
        put :update, params
      end
    end
  end

  describe "destroy" do
    let(:task) { job_tasks(:isdt) }
    let(:params) do
      {
        workspace_id: workspace.id,
        job_id: job.id,
        id: task.id
      }
    end

    it "lets a workspace member soft delete an job task" do
      delete :destroy, params
      response.should be_success
      task.reload.deleted?.should be_true
    end

    it "uses authorization" do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      delete :destroy, params
    end
  end
end