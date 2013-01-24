require_relative '../spec_helper'

describe "Data Source", :oracle_integration do
  include DataSourceHelpers

  describe "adding an oracle data source" do
    before do
      login(users(:admin))
      visit("#/data_sources")
      click_button "Add Data Source"
    end

    it "creates a instance" do
      within_modal do
        select_and_do_within_data_source "register_existing_oracle" do
          fill_in 'name', :with => "new_oracle_instance"
          fill_in 'host', :with => WEBPATH['oracle_instance_db']['oracle_host']
          fill_in 'port', :with => WEBPATH['oracle_instance_db']['oracle_port']
          fill_in 'dbName', :with => WEBPATH['oracle_instance_db']['oracle_database']
          fill_in 'dbUsername', :with => WEBPATH['oracle_instance_db']['oracle_user']
          fill_in 'dbPassword', :with => WEBPATH['oracle_instance_db']['oracle_pass']
        end
        click_button "Add Data Source"
      end

      #  See Tracker Story #42326927
      find(".gpdb_data_source ul").should have_content("new_oracle_instance")
    end
  end
end