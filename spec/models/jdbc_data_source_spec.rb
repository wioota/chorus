require 'spec_helper'

describe JdbcDataSource do
  let(:data_source) { data_sources(:jdbc) }

  describe 'validations' do
    it { should validate_presence_of(:host) }

    context 'when creating' do
      let(:data_source) { FactoryGirl.build(:jdbc_data_source) }
      it 'validates the owner account' do
        mock(data_source).owner_account { mock(FactoryGirl.build(:data_source_account)).valid? { true } }
        data_source.valid?
      end
    end
  end
end