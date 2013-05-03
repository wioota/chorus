require 'spec_helper'

describe AssociatedDataset do
  let(:gpdb_table) { FactoryGirl.create(:gpdb_table) }
  let(:workspace) { workspaces(:public) }
  let!(:associated_dataset) {
    FactoryGirl.create(:associated_dataset, :workspace => workspace, :dataset => gpdb_table)
  }

  describe "validations" do
    it { should validate_presence_of(:dataset) }
    it { should validate_presence_of(:workspace) }

    it 'doesnt allow associating a chorus view to a workspace' do
      association = FactoryGirl.build(:associated_dataset, :dataset => datasets(:chorus_view))
      association.should_not be_valid
      association.should have_error_on(:dataset).with_message(:invalid_type)
    end

    it "doesnt have duplicate workspace_id + dataset_id" do
      association = FactoryGirl.build(:associated_dataset, :workspace => workspace, :dataset => gpdb_table)
      association.should_not be_valid
      association.should have_error_on(:dataset_id).with_message(:taken).with_options(:value => gpdb_table.id)
    end

    it "doesnt validate against deleted associations" do
      associated_dataset.destroy
      association = FactoryGirl.build(:associated_dataset, :workspace => workspace, :dataset => gpdb_table)
      association.save.should be_true
    end
  end

  it_behaves_like 'a soft deletable model' do
    let(:model) { associated_dataset}
  end
end
