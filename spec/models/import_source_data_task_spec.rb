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
        :source_id => source_dataset.id,
        :destination_id => '2',
        :row_limit => '500',
        :truncate => "false"
      }
    end

    it "is coerced to a boolean" do
      task = JobTask.assemble!(planned_job_task, job)
      task.reload.payload.truncate.should == false
    end
  end

  describe '.assemble!' do
    context 'with a destination dataset' do
      let(:import_data) do
        {
          :source_id => source_dataset.id,
          :destination_id => '2',
          :row_limit => '500',
          :truncate => false
        }
      end
      let(:planned_job_task) do
        {
          :action => 'import_source_data',
          :is_new_table => false,
        }.merge!(import_data)
      end

      it "should make an associated ImportSourceDataTask" do
        expect {
          expect {
            JobTask.assemble!(planned_job_task, job)
          }.to change(ImportSourceDataTask, :count).by(1)
        }.to change(job.job_tasks.reload, :count).by(1)
      end

      it "should create an ImportTemplate as its payload" do
        task = JobTask.assemble!(planned_job_task, job)
        task.payload.source.should == source_dataset
        task.payload.destination_id.should == import_data[:destination_id].to_i
        task.payload.truncate.should == import_data[:truncate]
        task.payload.row_limit.should == import_data[:row_limit].to_i
      end
    end

    context 'with a new destination table' do
      let(:import_data) do
        {
          :source_id => source_dataset.id,
          :destination_name => 'FOO',
          :row_limit => '500',
          :truncate => false
        }
      end
      let(:planned_job_task) do
        {
          :action => 'import_source_data',
          :is_new_table => false,
        }.merge!(import_data)
      end

      it "should make an ImportSourceDataTask" do
        task = JobTask.assemble!(planned_job_task, job)
        task.payload.source_id.should == import_data[:source_id]
        task.payload.destination_name.should == import_data[:destination_name]
        task.payload.truncate.should == import_data[:truncate]
        task.payload.row_limit.should == import_data[:row_limit].to_i
        task.id.should_not be_nil
      end

      it 'cannot have the same destination_name as any existing dataset in the sandbox' do
        import_data[:destination_name] = job.workspace.sandbox.datasets.first.name
        expect {
          JobTask.assemble!(planned_job_task, job)
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
      stub(isdt.payload).set_destination_id!
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
      before do
        any_instance_of(WorkspaceImport) do |import|
          stub(import).table_does_not_exist { true }
          stub(import).tables_have_consistent_schema { true }
        end
      end
      let(:isdt) { FactoryGirl.create(:import_source_data_task_into_new_table) }

      context 'and the import completes successfully' do
        let(:dataset) { datasets(:table) }

        it 'changes the destination id to the newly created dataset id' do
          stub(ImportExecutor).run {true}
          stub(isdt.payload.workspace.sandbox.datasets).find_by_name { dataset }

          isdt.execute
          isdt.payload.destination_name.should be_nil
          isdt.payload.destination_id.should == dataset.id
        end
      end

      context 'and the import fails' do
        it 'keeps the destination_name and does not set the destination_id' do
          stub(ImportExecutor).run { raise }
          expect {
            isdt.execute
          }.not_to change(isdt.payload, :destination_name)
        end
      end
    end

    describe 'success' do
      it 'returns a successful JobTaskResult' do
        mock(ImportExecutor).run.with_any_args
        stub(isdt).set_destination_id!
        result = isdt.execute
        result.status.should == JobTaskResult::SUCCESS
        result.name.should == isdt.name
      end
    end

    describe 'failure' do
      it 'returns a failed JobTaskResult' do
        stub(ImportExecutor).run { raise }
        result = isdt.execute
        result.status.should == JobTaskResult::FAILURE
        result.name.should == isdt.name
      end
    end
  end

  describe "#build_task_name" do
    let(:task) { job_tasks(:isdt) }
    it "includes source dataset's name" do
      task.build_task_name.should include(task.payload.source.name)
    end
  end
end