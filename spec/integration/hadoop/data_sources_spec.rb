require_relative '../spec_helper'

describe "Data Sources", :database_integration do
  describe "adding a hadoop instance" do
    include DataSourceHelpers

    before do
      login(users(:admin))
      visit("#/instances")
      click_button "Add Data Source"
    end

    it "creates an hadoop instance" do
      within_modal do
        select_and_do_within_data_source "register_existing_hadoop" do
          fill_in 'name', :with => "new_hadoop_instance"
          fill_in 'host', :with => WEBPATH['hadoop_instance_db']['host']
          fill_in 'port', :with => WEBPATH['hadoop_instance_db']['port']
          fill_in 'username', :with => WEBPATH['hadoop_instance_db']['username']
          fill_in 'groupList', :with => WEBPATH['hadoop_instance_db']['group_list']
        end
        click_button "Add Data Source"
      end

      find(".hadoop_instance ul").should have_content("new_hadoop_instance")
    end
  end
end