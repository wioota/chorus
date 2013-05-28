require "spec_helper"

describe AlpineWorkfile do
  describe "validations" do
    it { should validate_presence_of :database_id }
  end
  let(:workspace) { workspaces(:public) }
  let(:user) { workspace.owner }
  let(:params) do
    {:workspace => workspace, :entity_subtype => "alpine",
     :file_name => "sfgj", :dataset_ids => [datasets(:table).id], :owner => user}
  end
  let(:model) { Workfile.build_for(params).tap { |file| file.save } }

  it "should have a content_type of work_flow" do
    model.content_type.should == 'work_flow'
  end

  it "should have an entity_subtype of 'alpine'" do
    model.entity_subtype.should == 'alpine'
  end

  describe "new" do
    context "when passed datasets" do
      let(:datasetA) { datasets(:table) }
      let(:datasetB) { datasets(:other_table) }
      let(:params) { {dataset_ids: [datasetA.id, datasetB.id]} }

      it 'assigns the database ID' do
        AlpineWorkfile.create(params).database_id.should == datasetA.database.id
      end

      it 'assigns the datasets' do
        AlpineWorkfile.create(params).datasets.should =~ [datasetA, datasetB]
      end

      context "and the datasets are from multiple databases" do
        before { stub(ActiveModel::Validations::HelperMethods).validates_presence_of }
        let(:datasetB) { FactoryGirl.create(:gpdb_table) }

        it "assigns too_many_databases error" do
          AlpineWorkfile.create(params).errors_on(:datasets).should include(:too_many_databases)
        end
      end

      context "and at least one of the datasets is a chorus view" do
        before { stub(ActiveModel::Validations::HelperMethods).validates_presence_of }
        let(:datasetB) { datasets(:chorus_view) }

        it "assigns too_many_databases error" do
          AlpineWorkfile.create(params).errors_on(:datasets).should include(:chorus_view_selected)
        end
      end
    end
  end
end