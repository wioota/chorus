require 'spec_helper'

def it_validates_duplicate(new_model, existing_model)
  it "returns false if a #{new_model.to_s.classify} is invalid" do
    FactoryGirl.create(new_model, :name => 'awesome_duplicate_name')
    FactoryGirl.build(existing_model, :name => 'awesome_duplicate_name').save(:validate => false)

    ExistingDataSourcesValidator.run.should be_false
  end
end

describe ExistingDataSourcesValidator do
  describe '.run' do
    it "returns true if the data sources are all valid" do
      ExistingDataSourcesValidator.run.should be_true
    end

    it_validates_duplicate(:gpdb_instance, :gnip_instance)
    it_validates_duplicate(:oracle_instance, :hadoop_instance)
    it_validates_duplicate(:hadoop_instance, :gnip_instance)
    it_validates_duplicate(:gnip_instance, :gnip_instance)
  end
end
