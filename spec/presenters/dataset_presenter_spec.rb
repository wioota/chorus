require 'spec_helper'

describe DatasetPresenter, :type => :view do
  before do
    @user = FactoryGirl.create :user
    set_current_user(@user)
  end

  it_behaves_like "dataset presenter", :gpdb_table

  let(:workspace) { FactoryGirl.create :workspace }
  let(:presenter) { described_class.new(dataset, view, {:workspace => workspace, :activity_stream => activity_stream}) }
  let(:activity_stream) { nil }
  let(:hash) { presenter.to_hash }

  describe ".associated_workspaces_hash" do
    let(:dataset) { FactoryGirl.create :gpdb_table }
    let!(:association) { FactoryGirl.create(:associated_dataset, :dataset => dataset, :workspace => workspace) }

    it "includes associated workspaces" do
      hash[:associated_workspaces][0][:id].should == workspace.id
      hash[:associated_workspaces][0][:name].should == workspace.name
    end

    context "when rendering an activity stream" do
      let(:activity_stream) { true }

      it "does not render any associated workspaces" do
        hash[:associated_workspaces].should be_empty
      end
    end
  end

  describe ".tableau_hash" do
    let(:dataset) { datasets(:chorus_view) }
    let(:workbook) { tableau_workbook_publications(:default) }

    it "includes associated tableau publications" do
      hash[:tableau_workbooks][0][:id].should == workbook.id
      hash[:tableau_workbooks][0][:name].should == workbook.name
      hash[:tableau_workbooks][0][:url].should == workbook.workbook_url
    end
  end

  describe "#to_hash" do
    context "when rendering an activity stream" do
      let(:workspace) { FactoryGirl.create :workspace }
      let(:dataset) { FactoryGirl.create :gpdb_table, :schema => schema }
      let(:schema) { FactoryGirl.create :gpdb_schema }
      let(:activity_stream) { true }

      it "renders only the schema id" do
        hash[:schema][:id].should == schema.id
        hash[:schema].keys.size.should == 1
      end

      it "renders empty/false value for mutiple keys" do
        hash[:frequency].should == ""
        hash[:tableau_workbooks].should == []
        hash[:associated_workspaces].should == []
        hash[:has_credentials].should == false
      end
    end

    context "for a sandbox table" do
      let(:workspace) { FactoryGirl.create :workspace }
      let(:dataset) { FactoryGirl.create :gpdb_table, :schema => schema }
      let(:schema) { FactoryGirl.create :gpdb_schema }

      before do
        workspace.sandbox_id = schema.id
      end

      it "has the correct type" do
        hash[:type].should == 'SANDBOX_TABLE'
      end

      it "includes comments fields" do
        hash[:recent_comments].should == []
        hash[:comment_count].should == 0
      end

      context 'when the table has tags' do
        let(:dataset) { datasets(:tagged) }

        it 'includes tags' do
          hash[:tags].count.should be > 0
          hash[:tags].should == Presenter.present(dataset.tags, @view)
        end
      end

      context "when it has comments" do
        let!(:dataset_note) { Events::NoteOnDataset.by(@user).add(:dataset => dataset, :body => 'Note on dataset') }

        it "presents the most recent note" do
          hash[:recent_comments].count.should == 1
          hash[:recent_comments][0][:body].should == "Note on dataset"
        end

        it "presents the number of comments/notes" do
          hash[:comment_count].should == 1
        end
      end
    end

    context "for a source table" do
      let(:workspace) { FactoryGirl.create :workspace, :sandbox => schema2 }
      let(:dataset) { FactoryGirl.create :gpdb_table, :schema => schema }
      let(:schema) { FactoryGirl.create :gpdb_schema }
      let(:schema2) { FactoryGirl.create :gpdb_schema }
      let(:association) { FactoryGirl.create(:associated_dataset, :dataset => dataset, :workspace => workspace) }
      let(:import_schedule) { FactoryGirl.create(:import_schedule, :source_dataset => dataset, :workspace => workspace, :start_datetime => Time.current(), :end_date => '2012-12-12', :frequency => "weekly", :workspace => workspace ) }

      before do
        [Import, ImportSchedule].each do |type|
          any_instance_of(type) do |o|
            stub(o).table_exists? { false }
          end
        end
        import_schedule
      end

      it "has the correct type and frequency" do
        hash[:type].should == 'SOURCE_TABLE'
        hash[:frequency].should == import_schedule.frequency
      end
    end
  end

  describe "complete_json?" do
    let(:dataset) { datasets(:table) }
    context "when rendering activities" do
      let(:activity_stream) { true }
      it "is not true" do
        presenter.complete_json?.should_not be_true
      end
    end

    context "when not rendering activities" do
      let(:activity_stream) { nil }
      it "is true" do
        presenter.complete_json?.should be_true
      end
    end
  end
end