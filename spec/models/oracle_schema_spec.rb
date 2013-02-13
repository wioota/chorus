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
end