require 'spec_helper'

describe JdbcDataset do
  let(:dataset) { datasets(:jdbc_table) }

  describe '#data_source_account_ids' do
    it 'returns data source account ids with access to the schema' do
      dataset.data_source_account_ids.should == dataset.schema.data_source_account_ids
    end
  end
end
