require 'spec_helper'

describe Schemas::ImportsController do
  describe '#create' do
    let(:source_dataset) { datasets(:oracle_table) }
    let(:schema) { schemas(:default) }
    let(:user) { schema.data_source.owner }

    before do
      any_instance_of(GreenplumConnection) do |connection|
        stub(connection).table_exists?(to_table) { table_exists }
      end
      log_in user
    end

    context 'when importing a dataset immediately' do
      context 'into a new destination dataset' do
        let(:table_exists) { false }
        let(:to_table) { "the_new_table" }
        let(:attributes) {
          HashWithIndifferentAccess.new(
            :to_table => to_table,
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

        it 'creates a new import' do
          expect {
            post :create, attributes
          }.to change(SchemaImport, :count).by(1)
          import = SchemaImport.last
          import.schema.should == schema
          import.to_table.should == to_table
          import.source_dataset.should == source_dataset
          import.truncate.should == false
          import.user_id.should == user.id
          import.sample_count.should == 12
          import.new_table.should == true
        end
      end
    end
  end
end