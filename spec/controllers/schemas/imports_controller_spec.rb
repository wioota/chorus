require 'spec_helper'

describe Schemas::ImportsController do
  describe '#create' do
    let(:source_dataset) { datasets(:oracle_table) }
    let(:schema) { source_dataset.schema }
    let(:user) { schema.data_source.owner }

    before do
      log_in user
    end

    context 'when importing a dataset immediately' do
      context 'into a new destination dataset' do
        let(:attributes) {
          HashWithIndifferentAccess.new(
            :to_table => "the_new_table",
            :sample_count => "12",
            :schema_id => schema.to_param,
            :truncate => "false",
            :dataset_id => source_dataset.to_param,
            :new_table => 'true'
          )
        }

        it 'has the right response code' do
          post :create, attributes
          response.code.should == "201"
        end

        it 'enqueues a new ImportExecutor.run job' do
          mock(QC.default_queue).enqueue_if_not_queued("ImportExecutor.run", anything) do |method, import_id|
            Import.find(import_id).tap do |import|
              import.schema.should == schema
              import.to_table.should == "the_new_table"
              import.source_dataset.should == source_dataset
              import.truncate.should == false
              import.user_id.should == user.id
              import.sample_count.should == 12
              import.new_table.should == true
            end
          end

          post :create, attributes
        end
      end
    end
  end
end