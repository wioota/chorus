require 'spec_helper'

describe OracleSchema do
  describe "#data_source" do
    let(:schema) {
      OracleSchema.create!(:name => 'test_schema', :data_source => data_sources(:oracle))
    }

    it "returns the schemas parent" do
      schema.reload.data_source.should == data_sources(:oracle)
    end
  end

  describe "validations" do
    let(:schema) { OracleSchema.new(:name => 'test_schema', :data_source => data_sources(:oracle)) }

    it "requires there is a data source" do
      schema.data_source = nil
      schema.valid?.should be_false
      schema.errors_on(:data_source).should include(:blank)
    end

    it "requires a name" do
      schema.name = nil
      schema.valid?.should be_false
      schema.errors_on(:name).should include(:blank)
    end

    it "requires a unique name per data source" do
      schema.save!
      new_schema = OracleSchema.new(:name=> 'test_schema', :data_source => data_sources(:oracle))
      new_schema.valid?.should be_false
      new_schema.errors_on(:name).should include(:taken)

      new_schema.data_source = FactoryGirl.build(:oracle_data_source)
      new_schema.valid?.should be_true
    end

  end

  describe "#class_for_type" do
    let(:schema) { schemas(:oracle) }
    it "should return OracleTable and OracleView correctly" do
      schema.class_for_type('t').should == OracleTable
      schema.class_for_type('v').should == OracleView
    end
  end

  describe '#active_tables_and_views' do
    let(:schema) { schemas(:oracle) }

    it 'includes tables' do
      table = nil
      expect {
        table = FactoryGirl.create(:oracle_table, :schema => schema)
      }.to change { schema.reload.active_tables_and_views.size }.by(1)
      schema.active_tables_and_views.should include(table)

      expect {
        table.mark_stale!
      }.to change { schema.reload.active_tables_and_views.size }.by(-1)
      schema.active_tables_and_views.should_not include(table)
    end

    it 'includes views' do
      view = nil

      expect {
        view = FactoryGirl.create(:oracle_view, :schema => schema)
      }.to change { schema.reload.active_tables_and_views.size }.by(1)
      schema.active_tables_and_views.should include(view)

      expect {
        view.mark_stale!
      }.to change { schema.reload.active_tables_and_views.size }.by(-1)
      schema.active_tables_and_views.should_not include(view)
    end
  end

  describe ".reindex_datasets" do
    let(:schema) { schemas(:oracle) }

    before do
      schema.datasets.each do |dataset|
        stub(Sunspot).index(dataset)
      end
    end

    it "calls solr_index on 'all' datasets" do
      schema.datasets.each do |dataset|
        mock(Sunspot).index(dataset)
      end
      OracleSchema.reindex_datasets(schema.id)
    end

    it "does not call solr_index on stale datasets" do
      stale_dataset = schema.datasets.first
      stale_dataset.mark_stale!
      dont_allow(Sunspot).index(stale_dataset)
      OracleSchema.reindex_datasets(schema.id)
    end

    it "calls Sunspot.commit" do
      mock(Sunspot).commit
      OracleSchema.reindex_datasets(schema.id)
    end

    it "continues if exceptions are raised" do
      schema.datasets.each do |dataset|
        mock(Sunspot).index(dataset) { raise "error!" }
      end
      mock(Sunspot).commit
      OracleSchema.reindex_datasets(schema.id)
    end
  end

  describe "destroy_schemas" do
    it "destroys schemas for given data source id" do
      data_source = data_sources(:oracle)
      data_source.destroy
      schemas = data_source.schemas
      schemas.should_not be_empty

      OracleSchema.destroy_schemas(data_source.id)
      schemas.reload.should be_empty
    end
  end

  it_behaves_like 'a subclass of schema' do
    let(:schema) { schemas(:oracle) }
  end

  it_behaves_like 'a soft deletable model' do
    let(:model) { schemas(:oracle)}
  end
end