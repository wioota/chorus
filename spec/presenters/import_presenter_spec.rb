require 'spec_helper'

describe ImportPresenter, :type => :view do
  before do
    @presenter = ImportPresenter.new(import, view)
  end
  let(:import) { imports(:three) }

  describe "#to_hash" do
    let(:hash) { @presenter.to_hash }

    it "includes the right keys" do
      hash.should have_key(:to_table)
      hash.should have_key(:destination_dataset_id)
      hash.should have_key(:started_stamp)
      hash.should have_key(:completed_stamp)
      hash.should have_key(:success)
      hash.should have_key(:source_dataset_id)
      hash.should have_key(:source_dataset_name)
      hash.should have_key(:file_name)
      hash.should have_key(:workspace_id)
    end

    it "should not blow up if the source dataset does not exist" do
      import.source_dataset_id = -1
      hash = ImportPresenter.new(import, view).to_hash

      hash[:source_dataset_name].should be_nil
    end
  end
end