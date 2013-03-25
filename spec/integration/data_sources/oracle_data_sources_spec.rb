require_relative '../spec_helper'

describe "Data Source", :oracle_integration do
  include DataSourceHelpers
  include GreenplumIntegration

  let(:schema) { OracleIntegration.real_schema }
  let(:data_source) { schema.data_source }

  let(:user) { users(:owner) }
  before do
    login user
  end

  describe "adding an oracle data source" do
    before do
      visit("#/data_sources")
      click_button "Add Data Source"
    end

    it "creates a data source" do
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

      find(".data_source ul").should have_content("new_oracle_data_source")
    end
  end

  describe "clicking on an Oracle data source" do
    before do
      visit("#/data_sources")
      click_on data_source.name
    end

    it "shows a list of the data source's schemas" do
      wait_for_page_load

      page.should have_content schema.name
    end
  end

  describe "clicking on an Oracle schema" do
    before do
      schema.datasets.size.should > 0
      visit("#/data_sources/#{data_source.id}/schemas")
      find(:xpath, "//a[text()='#{schema.name}']").click
    end

    it "shows a list of the datasets in the schema" do
      wait_for_page_load
      schema.datasets.each do |dataset|
        page.should have_content dataset.name
      end
    end
  end
end