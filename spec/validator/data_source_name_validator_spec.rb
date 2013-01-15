require 'spec_helper'

def it_validates_against(model_type)
  it "fails if a #{model_type} has the same name as the record" do
    FactoryGirl.create(model_type.to_s.underscore.to_sym, :name => name)
    record.valid?.should == false
    record.should have_error_on(:name).with_message(:taken)
  end
end

describe DataSourceNameValidator do
  let(:name) { 'theodore' }
  let(:record) {
    Class.new(ActiveRecord::Base) {
      self.table_name = 'data_sources'
      attr_accessible :name
      validates_with DataSourceNameValidator
    }.new(:name => name)
  }

  it "runs validate for objects that include it" do
    any_instance_of(DataSourceNameValidator) do |obj|
      mock(obj).validate(record) { true }
    end

    record.valid?
  end

  describe "#validate" do
    it "passes if the record doesn't have a name" do
      record.name = nil
      record.valid?.should be_true
    end

    it "passes if the record name is unique across data sources" do
      record.valid?.should be_true
    end

    it "passes on model update" do
      OriginalGpdbInstance = GpdbInstance

      class GpdbInstance < DataSource
        validates_with DataSourceNameValidator
      end

      record = FactoryGirl.build(:gpdb_instance, :name => name)
      record.save
      record.reload.valid?.should be_true

      # don't leak modified instance class
      Object.class_eval do
        const_set(:GpdbInstance, OriginalGpdbInstance)
        remove_const(:OriginalGpdbInstance)
      end
    end

    it_validates_against(GpdbInstance)
    it_validates_against(OracleInstance)
    it_validates_against(HadoopInstance)
    it_validates_against(GnipInstance)

    it "it matches data source names regardless of case" do
      FactoryGirl.create(:gnip_instance, :name => name.capitalize)
      record.valid?.should == false
      record.should have_error_on(:name).with_message(:taken)
    end
  end
end