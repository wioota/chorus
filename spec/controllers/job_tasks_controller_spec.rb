require 'spec_helper'
#require 'will_paginate/array'

describe JobTasksController do
  let(:workspace) { workspaces(:public) }
  let(:job) { jobs(:default) }
  let(:user) { users(:owner) }
  let(:dataset) { datasets(:table) }

  before do
    log_in user
  end

  describe '#create' do
    let(:params) do
      {
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
          :destination_id => '2',
          :row_limit => '500',
          :truncate => false,
          :index => 150
        }
      end

      context 'with an existing destination table' do
        it 'creates a job task' do
          expect do
            post :create, params
          end.to change(JobTask, :count).by(1)
        end
      end

      context 'with a new destination table' do
        let(:planned_job_task) do
          {
            :action => 'import_source_data',
            :source_id => dataset.id,
            :new_table_name => 'into_this_one',
            :row_limit => '500',
            :truncate => false,
            :index => '45'
          }
        end

        it 'creates a job task' do
          expect do
            post :create, params
          end.to change(JobTask, :count).by(1)
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
end