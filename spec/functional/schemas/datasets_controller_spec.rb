require 'spec_helper'

describe DatasetsController, :greenplum_integration => true, :type => :controller do
  describe "#index" do
    let(:user) { users(:admin) }
    let(:schema) { GreenplumIntegration.real_database.schemas.find_by_name('test_schema') }

    before do
      log_in user

      # Make sure creation order doesn't affect sorting
      GreenplumIntegration.exec_sql_line('CREATE TABLE test_schema."1first" ()')
    end

    after do
      # Clean up table created for tests
      GreenplumIntegration.exec_sql_line('DROP TABLE test_schema."1first"')
    end

    it "presents the correct count / pagination information" do
      get :index, :schema_id => schema.to_param, :page => "1", :per_page => "5"
      decoded_pagination.records.should == 17
      decoded_pagination.total.should == 4
    end

    it "presents a sorted list of datasets" do
      get :index, :schema_id => schema.to_param
      decoded_response.map(&:object_name).first.should eq('1first')
      decoded_response.map(&:object_name).should eq(decoded_response.map(&:object_name).sort)
    end

    describe "filtering by name" do
      it "presents the correct count / pagination information" do
        get :index, :schema_id => schema.to_param, :filter => 'CANDY', :page => "1", :per_page => "5"
        decoded_pagination.records.should == 7
        decoded_pagination.total.should == 2
      end

      it "only presents datasets that match the name filter" do
        get :index, :schema_id => schema.to_param, :filter => 'CANDY'
        decoded_response.map(&:object_name).should include('candy_empty')
        decoded_response.map(&:object_name).should_not include('different_names_table')
      end
    end

    describe "only requesting tables" do
      it "only presents tables" do
        get :index, :schema_id => schema.to_param, :tables_only => "true"
        decoded_response.map(&:object_name).should_not include("view1")
      end
    end
  end
end