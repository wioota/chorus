require 'spec_helper'

describe AssociatedDataset do
  let(:gpdb_table) { FactoryGirl.create(:gpdb_table) }
  let(:workspace) { workspaces(:public) }
  let!(:associated_dataset) {
    association = described_class.new
    association.workspace = workspace
    association.dataset = gpdb_table
    association.save!

    association
  }

  describe "validations" do
    it { should validate_presence_of(:dataset_id) }
    it { should validate_presence_of(:workspace_id) }

    it "doesnt have duplicate workspace_id + dataset_id" do
      association = FactoryGirl.build(:associated_dataset, :workspace => workspace, :dataset => gpdb_table)
      association.should_not be_valid
      association.errors[:dataset_id].should include [:taken, {:value => gpdb_table.id}]
    end

    it "doesnt validate against deleted associations" do
      associated_dataset.destroy
      association = FactoryGirl.build(:associated_dataset, :workspace => workspace, :dataset => gpdb_table)
      association.should be_valid
    end
  end

  describe "#destroy" do
    it "should not delete the database entry" do
      associated_dataset.destroy
      expect {
        associated_dataset.reload
      }.to_not raise_error(Exception)
    end

    it "should update the deleted_at field" do
      associated_dataset.destroy
      associated_dataset.reload.deleted_at.should_not be_nil
    end

    it "should be hidden from subsequent #find calls" do
      associated_dataset.destroy
      AssociatedDataset.find_by_id(associated_dataset.id).should be_nil
    end
  end
end
