require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Sandbox", :database_integration do

  let(:workspace) { workspaces(:private_with_no_collaborators) }
  let(:instance) { InstanceIntegration.real_gpdb_instance }
  let(:database) { InstanceIntegration.real_database }
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
      page.execute_script("$('select[name=instance]').val('#{instance.id}')")
      page.execute_script("$('select[name=instance]').selectmenu('refresh')")
      page.execute_script("$('select[name=instance]').change()")
      page.find("div.instance span.ui-selectmenu-text").should have_content(instance.name)

      #database
      page.find("div.database span.ui-selectmenu-text").should have_content("Select one")
      page.execute_script("$('select[name=database]').val('#{database.id}')")
      page.execute_script("$('select[name=database]').selectmenu('refresh')")
      page.execute_script("$('select[name=database]').change()")
      page.find("div.database span.ui-selectmenu-text").should have_content(database.name)

      #schema
      page.find("div.schema span.ui-selectmenu-text").should have_content("Select one")
      page.execute_script("$('select[name=schema]').val('#{schema.id}')")
      page.execute_script("$('select[name=schema]').selectmenu('refresh')")
      page.execute_script("$('select[name=schema]').change()")
      page.find("div.schema span.ui-selectmenu-text").should have_content(schema.name)

      click_button "Add Sandbox"
    end

    workspace.reload.sandbox.should == schema
  end
end

