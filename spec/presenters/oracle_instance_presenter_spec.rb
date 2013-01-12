require 'spec_helper'

describe OracleInstancePresenter, :type => :view do

  let(:oracle_instance) { OracleInstance.new }
  let(:options) { {} }
  let(:presenter) { OracleInstancePresenter.new(oracle_instance, view, options) }

  let(:hash) { presenter.to_hash }

  describe "#to_hash" do
    it "includes the right keys" do
      hash.should have_key(:id)
      hash.should have_key(:name)
      hash.should have_key(:port)
      hash.should have_key(:host)
      hash.should have_key(:description)
      hash.should have_key(:maintenance_db)
    end
  end
end