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
      association.should have_error_on(:dataset).with_message(:invalid_type)
    end

    it "doesnt have duplicate workspace_id + dataset_id" do
      association = FactoryGirl.build(:associated_dataset, :workspace => workspace, :dataset => gpdb_table)
      association.should have_error_on(:dataset).with_message(:already_associated).with_options(:workspace_name => workspace.name)
    end

    context "when the workspace does not automatically associate sandbox datasets " do
      before do
        workspace.show_sandbox_datasets = false
      end

      let(:dataset) { datasets(:table)}

      it "allows associations of sandbox datasets" do
        workspace.sandbox.should == dataset.schema
        association = FactoryGirl.build(:associated_dataset, :workspace => workspace, :dataset => dataset)
        association.should be_valid
      end
    end

    context "when the workspace does automatically associate sandbox datasets" do
      before do
        workspace.show_sandbox_datasets = true
      end

      let(:dataset) { datasets(:table)}


      it "does not allow associations of sandbox datasets" do
        workspace.sandbox.should == dataset.schema
        association = FactoryGirl.build(:associated_dataset, :workspace => workspace, :dataset => dataset)
        association.should have_error_on(:dataset).with_message(:already_associated).with_options(:workspace_name => workspace.name)
      end
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
