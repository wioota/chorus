require 'spec_helper'

describe ImportSourceDataTask do
  let(:job) { jobs(:default) }
  let(:source_dataset) { datasets(:table) }

  describe '#assemble!' do
    context 'with a destination dataset' do
      let(:additional_data) do
        {
          "source_id" => source_dataset.id,
          "destination_id" => '2',
          "row_limit" => '500',
          "truncate" => false
        }
      end
      let(:planned_job_task) do
        {
          :action => 'import_source_data',
          :is_new_table => false,
          :index => 1000,
        }.merge!(additional_data)
      end

      it "should make an ImportSourceDataTask" do
        task = ImportSourceDataTask.assemble!(planned_job_task, job)
        task.additional_data.should == additional_data
        task.id.should_not be_nil
      end

      it 'should set the display name' do
        task = ImportSourceDataTask.assemble!(planned_job_task, job)
        task.name.should == "Import " + source_dataset.name
      end
    end

    context 'with a new destination table' do
      let(:additional_data) do
        {
          "source_id" => source_dataset.id,
          "destination_name" => 'FOO',
          "row_limit" => '500',
          "truncate" => false
        }
      end
      let(:planned_job_task) do
        {
          :action => 'import_source_data',
          :is_new_table => false,
          :index => 1000,
        }.merge!(additional_data)
      end

      it "should make an ImportSourceDataTask" do
        task = ImportSourceDataTask.assemble!(planned_job_task, job)
        task.additional_data.should == additional_data
        task.id.should_not be_nil
      end

      it 'should set the display name' do
        task = ImportSourceDataTask.assemble!(planned_job_task, job)
        task.name.should == "Import " + source_dataset.name
      end

      it 'cannot have the same destination_name as any existing dataset in the sandbox' do
        additional_data["destination_name"] = job.workspace.sandbox.datasets.first.name
        expect {
          ImportSourceDataTask.assemble!(planned_job_task, job)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end