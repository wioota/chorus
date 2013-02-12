require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Sandbox", :greenplum_integration do

  let(:workspace) { workspaces(:private_with_no_collaborators) }
  let(:instance) { GreenplumIntegration.real_data_source }
  let(:database) { GreenplumIntegration.real_database }
  let(:schema) { database.schemas.first }

  before do
    login(users(:admin))
  end

  it "creates sandbox in workspace" do
    visit("#/workspaces/#{workspace.id}")
    click_link "Add a sandbox"

    within_modal do
      #instance
      page.find("div.instance span.ui-selectmenu-text").should have_content("Select one")
      select_item("select[name=instance]", instance.id)
      page.find("div.instance span.ui-selectmenu-text").should have_content(instance.name)

      #database
      page.find("div.database span.ui-selectmenu-text").should have_content("Select one")
      select_item("select[name=database]", database.id)
      page.find("div.database span.ui-selectmenu-text").should have_content(database.name)

      #schema
      page.find("div.schema span.ui-selectmenu-text").should have_content("Select one")
      select_item("select[name=schema]", schema.id)
      page.find("div.schema span.ui-selectmenu-text").should have_content(schema.name)

      click_button "Add Sandbox"
    end

    workspace.reload.sandbox.should == schema
  end
end

