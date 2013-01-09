require 'spec_helper'

describe DataSourceNameValidator do
  let(:test_class) {
    Class.new(ActiveRecord::Base) do
      self.table_name = 'datasets'
      attr_accessible :name

      include ActiveModel::Validations
      validates_with DataSourceNameValidator
    end
  }

  let(:name) { 'theodore' }
  let(:record) { test_class.new(:name => name) }

  it "runs validate for objects that include it" do
    any_instance_of(DataSourceNameValidator) do |obj|
      mock(obj).validate(record) { true }
    end

    record.valid?
  end

  describe "#validate" do
    it "passes if the record name is unique across data sources" do
      record.valid?
    end

    it "fails if a GPDBInstance has the same name as the record" do
      FactoryGirl.create(:gpdb_instance, :name => name)
      record.valid?.should == false
      record.should have_error_on(:name).with_message(:in_use)
    end

    it "fails if a HadoopInstance has the same name as the record" do
      FactoryGirl.create(:hadoop_instance, :name => name)
      record.valid?.should == false
      record.should have_error_on(:name).with_message(:in_use)
    end

    it "fails if a GnipInstance has the same name as the record" do
      FactoryGirl.create(:gnip_instance, :name => name)
      record.valid?.should == false
      record.should have_error_on(:name).with_message(:in_use)
    end

    it "it matches data source names regardless of case" do
      FactoryGirl.create(:gnip_instance, :name => name.capitalize)
      record.valid?.should == false
      record.should have_error_on(:name).with_message(:in_use)
    end
  end
end