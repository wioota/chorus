require 'spec_helper'

describe OracleDataSourcePresenter, :type => :view do

  let(:oracle_data_source) { OracleDataSource.new }
  let(:options) { {} }
  let(:presenter) { OracleDataSourcePresenter.new(oracle_data_source, view, options) }

  let(:hash) { presenter.to_hash }

  describe "#to_hash" do
    it "includes the right keys" do
      hash.should have_key(:id)
      hash.should have_key(:name)
      hash.should have_key(:port)
      hash.should have_key(:host)
      hash.should have_key(:description)
      hash.should have_key(:db_name)
      hash[:entity_type].should == "oracle_data_source"
    end
  end
end