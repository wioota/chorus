require 'spec_helper'

describe ImportSourceDataTask do
  let(:job) { jobs(:default) }
  let(:source_dataset) { datasets(:table) }

  describe '#truncate' do
    let(:planned_job_task) do
      {
        :action => 'import_source_data',
        :is_new_table => false,
        :index => 1000,
        "source_id" => source_dataset.id,
        "destination_id" => '2',
        "row_limit" => '500',
        "truncate" => "false"
      }
    end

    it "is coerced to a boolean" do
      task = ImportSourceDataTask.assemble!(planned_job_task, job)
      task.reload.truncate.should == false
    end

    it "raises an error if the value is anything other than 'true' or 'false'" do
      planned_job_task["truncate"] = 'pajamas'
      expect do
        ImportSourceDataTask.assemble!(planned_job_task, job)
      end.to raise_error(ArgumentError)
    end
  end

  describe '.assemble!' do
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

  describe '#execute' do
    let(:isdt) { job_tasks(:isdt) }

    before do
      any_instance_of(GreenplumConnection) { |gp| stub(gp).table_exists? { false } }
    end

    it "creates an Import Object" do
      mock(ImportExecutor).run.with_any_args
      stub(isdt).set_destination_id!
      expect {
        isdt.execute
      }.to change(Import, :count).by(1)
    end

    it "Runs the import through the import executor" do
      mock(ImportExecutor).run.with_any_args
      stub(isdt).set_destination_id!
      isdt.execute
    end

    describe 'when importing into a new table' do
      context 'and the import completes successfully' do
        let(:dataset) { datasets(:table) }
        before do
          isdt.destination_name = dataset.name
        end

        it 'changes the destination id to the newly created dataset id' do
          stub(ImportExecutor).run {true}
          stub(isdt.job.workspace.sandbox.datasets).find_by_name { dataset }
          isdt.execute
          isdt.destination_name.should be_nil
          isdt.destination_id.should == dataset.id
        end
      end

      context 'and the import fails' do
        it 'keeps the destination_name and does not set the destination_id' do
          stub(ImportExecutor).run { raise }
          expect {
            expect {
              isdt.execute
            }.to raise_error(JobTask::JobTaskFailure)
          }.not_to change(isdt, :destination_name)
        end
      end
    end

    describe 'success' do
      it 'returns true' do
        mock(ImportExecutor).run.with_any_args
        stub(isdt).set_destination_id!
        isdt.execute.should be_true
      end
    end

    describe 'failure' do
      it 'raises JobTaskFailure error' do
        stub(ImportExecutor).run { raise }
        expect {
          isdt.execute
        }.to raise_error(JobTask::JobTaskFailure)
      end
    end

  end
end