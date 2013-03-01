require 'spec_helper'

describe Dataset do
  let(:schema) { schemas(:default) }
  let(:other_schema) { schemas(:other_schema) }
  let(:dataset) { datasets(:table) }
  let(:source_table) { datasets(:source_table) }

  it_behaves_like "a notable model" do
    let!(:note) do
      Events::NoteOnDataset.create!({
          :actor => users(:owner),
          :dataset => model,
          :body => "This is the body"
      }, :as => :create)
    end

    let!(:model) { dataset }
  end

  describe "associations" do
    it { should belong_to :schema }
    it { should have_many :activities }
    it { should have_many :events }
    it { should have_many :notes }
    it { should have_many :comments }
  end

  describe "workspace association" do
    let(:workspace) { workspaces(:public) }

    it "can be bound to workspaces" do
      source_table.bound_workspaces.should include workspace
    end
  end

  describe "validations" do
    it { should validate_presence_of :schema }
    it { should validate_presence_of :name }

    it "validates uniqueness of name in the database" do
      duplicate_dataset = GpdbTable.new
      duplicate_dataset.schema = dataset.schema
      duplicate_dataset.name = dataset.name
      expect {
        duplicate_dataset.save!(:validate => false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "does not bother validating uniqueness of name in the database if the record is deleted" do
      duplicate_dataset = GpdbTable.new
      duplicate_dataset.schema = dataset.schema
      duplicate_dataset.name = dataset.name
      duplicate_dataset.deleted_at = Time.current
      duplicate_dataset.save(:validate => false).should be_true
    end

    it "validates uniqueness of name, scoped to schema id" do
      duplicate_dataset = GpdbTable.new
      duplicate_dataset.schema = dataset.schema
      duplicate_dataset.name = dataset.name
      duplicate_dataset.should have_at_least(1).error_on(:name)
      duplicate_dataset.schema = other_schema
      duplicate_dataset.should have(:no).errors_on(:name)
    end

    it "validates uniqueness of name, scoped to type" do
      duplicate_dataset = ChorusView.new
      duplicate_dataset.name = dataset.name
      duplicate_dataset.schema = dataset.schema
      duplicate_dataset.should have(:no).errors_on(:name)
    end

    describe "default scope" do
      it "does not contain deleted datasets" do
        deleted_chorus_view = ChorusView.first
        deleted_chorus_view.update_attribute :deleted_at, Time.current
        Dataset.all.should_not include(deleted_chorus_view)
      end
    end

    it "validate uniqueness of name, scoped to deleted_at" do
      duplicate_dataset = GpdbTable.new
      duplicate_dataset.name = dataset.name
      duplicate_dataset.schema = dataset.schema
      duplicate_dataset.should have_at_least(1).error_on(:name)
      duplicate_dataset.deleted_at = Time.current
      duplicate_dataset.should have(:no).errors_on(:name)
    end
  end

  describe ".with_name_like" do
    it "matches anywhere in the name, regardless of case" do
      dataset.update_attributes!({:name => "amatCHingtable"}, :without_protection => true)

      Dataset.with_name_like("match").count.should == 1
      Dataset.with_name_like("MATCH").count.should == 1
    end

    it "returns all objects if name is not provided" do
      Dataset.with_name_like(nil).count.should == Dataset.count
    end
  end

  describe ".filter_by_name" do
    let(:second_dataset) {
      GpdbTable.new({:name => 'rails_only_table', :schema => schema}, :without_protection => true)
    }
    let(:dataset_list) {
      [dataset, second_dataset]
    }

    it "matches anywhere in the name, regardless of case" do
      dataset.update_attributes!({:name => "amatCHingtable"}, :without_protection => true)

      Dataset.filter_by_name(dataset_list, "match").count.should == 1
      Dataset.filter_by_name(dataset_list, "MATCH").count.should == 1
    end

    it "returns all objects if name is not provided" do
      Dataset.filter_by_name(dataset_list, nil).count.should == dataset_list.count
    end
  end

  describe "#all_rows_sql" do
    it "returns the correct sql" do
      dataset = datasets(:table)
      dataset.all_rows_sql().strip.should == %Q{SELECT * FROM "#{dataset.name}"}
    end

    context "with a limit" do
      it "uses the limit" do
        dataset = datasets(:table)
        dataset.all_rows_sql(10).should match "LIMIT 10"
      end
    end
  end

  describe ".find_and_verify_in_source" do
    let(:user) { users(:owner) }
    let(:dataset) { datasets(:table) }

    before do
      stub(Dataset).find(dataset.id) { dataset }
    end

    context 'when it exists in the source database' do
      before do
        mock(dataset).verify_in_source(user) { true }
      end

      it 'returns the dataset' do
        described_class.find_and_verify_in_source(dataset.id, user).should == dataset
      end
    end

    context 'when it does not exist in Greenplum' do
      before do
        mock(dataset).verify_in_source(user) { false }
      end

      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.find_and_verify_in_source(dataset.id, user)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "search fields" do
    let(:dataset) { datasets(:searchquery_table) }
    it "indexes text fields" do
      Dataset.should have_searchable_field :name
      Dataset.should have_searchable_field :table_description
      Dataset.should have_searchable_field :database_name
      Dataset.should have_searchable_field :schema_name
      Dataset.should have_searchable_field :column_name
      Dataset.should have_searchable_field :column_description
    end

    it "returns the schema name for schema_name" do
      dataset.schema_name.should == dataset.schema.name
    end

    it "returns the database name for database_name" do
      dataset.database_name.should == dataset.schema.database.name
    end

    it "un-indexes the dataset when it becomes stale" do
      mock(dataset).solr_remove_from_index
      dataset.mark_stale!
    end

    it "re-indexes the dataset when it becomes un stale" do
      dataset.mark_stale!
      mock(dataset).solr_index
      dataset.stale_at = nil
      dataset.save!
    end

    describe "workspace_ids" do
      let(:workspace) { workspaces(:search_public) }
      let(:chorus_view) { datasets(:searchquery_chorus_view) }

      it "includes the id of all associated workspaces" do
        chorus_view.found_in_workspace_id.should include(workspace.id)
      end

      it "includes the id of all workspaces that include the dataset through a sandbox" do
        dataset.found_in_workspace_id.should include(workspace.id)
      end
    end
  end

  it_should_behave_like "taggable models", [:datasets, :table]
end