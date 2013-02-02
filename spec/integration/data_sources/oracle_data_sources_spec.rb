require_relative '../spec_helper'

describe "Data Source", :oracle_integration do
  include DataSourceHelpers
  include InstanceIntegration

  describe "adding an oracle data source" do
    before do
      login(users(:admin))
      visit("#/data_sources")
      click_button "Add Data Source"
    end

    it "creates a instance" do
      within_modal do
        select_and_do_within_data_source "register_existing_oracle" do
          fill_in 'name', :with => "new_oracle_data_source"
          fill_in 'host', :with => WEBPATH['oracle_data_source_db']['oracle_host']
          fill_in 'port', :with => WEBPATH['oracle_data_source_db']['oracle_port']
          fill_in 'dbName', :with => WEBPATH['oracle_data_source_db']['oracle_database']
          fill_in 'dbUsername', :with => WEBPATH['oracle_data_source_db']['oracle_user']
          fill_in 'dbPassword', :with => WEBPATH['oracle_data_source_db']['oracle_pass']
        end
        click_button "Add Data Source"
      end

      #  See Tracker Story #42326927
      find(".data_source ul").should have_content("new_oracle_data_source")
    end
  end

  describe "clicking on an Oracle data source" do
    let(:data_source) { InstanceIntegration.real_oracle_data_source }

    before do
      login(users(:admin))
      visit("#/data_sources")
      click_on data_source.name
    end

    it "shows a list of the data source's schemas" do
      data_source.refresh_schemas.each do |schema|
        page.should have_content schema.name
      end
    end
  end
end