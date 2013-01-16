require_relative 'spec_helper'

describe "Data Sources", :database_integration do
  describe "adding a greenplum instance" do
    include DataSourceHelpers
    
    before do
      login(users(:admin))
      visit("#/instances")
      click_button "Add Data Source"
    end

    it "creates a gpdb instance" do
      within_modal do
        select_and_do_within_data_source "register_existing_greenplum" do
          fill_in 'name', :with => "new_gpdb_instance"
          fill_in 'host', :with => WEBPATH['gpdb_instance_db']['gpdb_host']
          fill_in 'port', :with => WEBPATH['gpdb_instance_db']['gpdb_port']
          fill_in 'dbUsername', :with => WEBPATH['gpdb_instance_db']['gpdb_user']
          fill_in 'dbPassword', :with => WEBPATH['gpdb_instance_db']['gpdb_pass']
        end
        click_button "Add Data Source"
      end

      find(".gpdb_instance ul").should have_content("new_gpdb_instance")
    end
  end
end