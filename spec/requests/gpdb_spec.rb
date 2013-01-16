require 'spec_helper'

describe "gpdb instances", :database_integration, :network do
  let(:valid_attributes) do
    {
        :name => "chorusgpdb42",
        :port => 5432,
        :host => InstanceIntegration::REAL_GPDB_HOST,
        :maintenance_db => "postgres",
        :db_username => InstanceIntegration::REAL_GPDB_USERNAME,
        :db_password => InstanceIntegration::REAL_GPDB_PASSWORD
    }
  end

  let!(:user) { FactoryGirl.create :user, :username => 'some_user', :password => 'secret' }

  context "after the user has logged in" do
    before do
      post "/sessions", :session => { :username => "some_user", :password => "secret" }
    end

    it "can be created" do
      post "/data_sources", :data_source => valid_attributes

      response.code.should == "201"
    end

    it "can be updated" do
      post "/data_sources", :data_source => valid_attributes
      data_source_id = decoded_response.id
      put "/data_sources/#{data_source_id}",
          :data_source => valid_attributes.merge(:name => "new_name")

      decoded_response.name.should == "new_name"
    end
  end
end
