require_relative '../spec_helper'

describe "Data Sources", :greenplum_integration do
  describe "adding a greenplum data source" do
    include DataSourceHelpers
    
    before do
      login(users(:admin))
      visit("#/data_sources")
      click_button "Add Data Source"
    end

    it "creates a gpdb data source" do
      within_modal do
        select_and_do_within_data_source "register_existing_greenplum" do
          fill_in 'name', :with => "new_gpdb_data_source"
          fill_in 'host', :with => WEBPATH['gpdb_data_source_db']['gpdb_host']
          fill_in 'port', :with => WEBPATH['gpdb_data_source_db']['gpdb_port']
          fill_in 'dbUsername', :with => WEBPATH['gpdb_data_source_db']['gpdb_user']
          fill_in 'dbPassword', :with => WEBPATH['gpdb_data_source_db']['gpdb_pass']
        end
        click_button "Add Data Source"
      end

      find(".data_source ul").should have_content("new_gpdb_data_source")
    end
  end

  describe "viewing a Greenplum data source" do
    let(:database) { GreenplumIntegration.real_database }

    before do
      login(users(:admin))
      visit("#/databases/#{database.id}")
    end

    it "shows a list of the data source's databases" do
      database.schemas.each do |schema|
        page.should have_content schema.name
      end
    end
  end
end