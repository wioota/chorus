require 'spec_helper'

describe OracleSchemaPresenter, :type => :view do
  before do
    2.times { FactoryGirl.create(:oracle_table, :schema => schema) }
    schema.reload
    schema.touch :refreshed_at
  end

  let(:schema) { FactoryGirl.create(:oracle_schema) }
  let(:presenter) { OracleSchemaPresenter.new(schema, view) }
  let(:hash) { presenter.to_hash }

  describe '#to_hash' do
    it 'includes the fields' do
      hash[:id].should == schema.id
      hash[:name].should == schema.name
      hash[:dataset_count].should == 2
      hash[:refreshed_at].should == schema.refreshed_at
      hash[:refreshed_at].should_not be_nil
      hash[:entity_type].should == "oracle_schema"
      hash[:instance][:id].should == schema.data_source.id
      hash[:instance][:name].should == schema.data_source.name
    end
  end
end