require 'spec_helper'

describe SchemaImport do
  let(:schema) { schemas(:default) }
  let(:import) { imports(:to_schema) }

  describe 'associations' do
    it { should belong_to :schema }
  end

  describe '#schema' do
    it 'has an associated schema' do
      import.schema.should == schema
    end
  end
end